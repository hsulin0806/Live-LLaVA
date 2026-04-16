#!/usr/bin/env python3
#
# Example for vision/language model inference on continuous video streams
# by keeping a rolling history of the past N frames (--max-images=N)
#
# You can run it on video files or devices like this:
#
#    python3 -m nano_llm.vision.video \
#      --model Efficient-Large-Model/VILA1.5-3b \
#      --max-images 8 \
#      --max-new-tokens 48 \
#      --video-input /data/my_video.mp4 \
#      --video-output /data/my_output.mp4 \
#      --prompt 'What changes occurred in the video?'
#
# The model should have been trained to understand video sequences (like VILA-1.5)
#
import time
import logging
import re

from nano_llm import NanoLLM, ChatHistory, remove_special_tokens
from nano_llm.utils import ArgParser, load_prompts
from nano_llm.plugins import VideoSource, VideoOutput

from termcolor import cprint
from jetson_utils import cudaMemcpy, cudaToNumpy, cudaFont

# parse args and set some defaults
parser = ArgParser(extras=ArgParser.Defaults + ['prompt', 'video_input', 'video_output'])
parser.add_argument("--max-images", type=int, default=8, help="the number of video frames to keep in the history")
parser.add_argument("--infer-interval-sec", type=float, default=3.0, help="seconds between each new inference")
parser.add_argument("--subtitle-hold-sec", type=float, default=3.0, help="seconds to keep subtitle on screen before replacing")
parser.add_argument("--subtitle-max-chars", type=int, default=160, help="maximum characters shown in subtitle")
parser.add_argument("--subtitle-line-chars", type=int, default=0, help="approx characters per subtitle line (<=0 for auto full-width)")
parser.add_argument("--subtitle-max-lines", type=int, default=6, help="maximum subtitle lines")
args = parser.parse_args()

prompts = load_prompts(args.prompt)

if not prompts:
    prompts = ["What changes occurred in the video?"] # "Concisely state what is happening in the video."
    
if not args.model:
    args.model = "Efficient-Large-Model/VILA1.5-3b"

print(args)

# load vision/language model
model = NanoLLM.from_pretrained(
    args.model, 
    api=args.api,
    quantization=args.quantization, 
    max_context_len=args.max_context_len,
    vision_api=args.vision_api,
    vision_model=args.vision_model,
    vision_scaling=args.vision_scaling, 
)

assert(model.has_vision)

# create the chat history
chat_history = ChatHistory(model, args.chat_template, args.system_prompt)

# warm-up model
chat_history.append(role='user', text='What is 2+2?')
logging.info(f"Warmup response:  '{model.generate(chat_history.embed_chat()[0], streaming=False)}'".replace('\n','\\n'))
chat_history.reset()

# open the video stream
num_images = 0
last_image = None
last_text = ''
last_text_time = 0.0
last_infer_time = 0.0

def split_subtitle_lines(text, line_chars=30):
    text = (text or '').strip()
    if not text:
        return []

    if ' ' in text:
        words = text.split()
        lines, line = [], ''
        for word in words:
            if len(line) + len(word) + (1 if line else 0) <= line_chars:
                line = f"{line} {word}".strip()
            else:
                if line:
                    lines.append(line)
                if len(word) <= line_chars:
                    line = word
                else:
                    for i in range(0, len(word), line_chars):
                        lines.append(word[i:i+line_chars])
                    line = ''
        if line:
            lines.append(line)
        return lines

    return [text[i:i+line_chars] for i in range(0, len(text), line_chars)]

def draw_subtitle(image, text):
    if args.subtitle_line_chars <= 0:
        line_chars = max(16, int((image.width - 16) / max(8, font.GetSize() * 0.55)))
    else:
        line_chars = max(8, args.subtitle_line_chars)

    lines = split_subtitle_lines(text, line_chars=line_chars)
    if not lines:
        return

    y = 5
    line_spacing = font.GetSize() + 6
    for line in lines[:max(1, args.subtitle_max_lines)]:
        font.OverlayText(image, text=line, x=5, y=y, color=(120,215,21), background=font.Gray50)
        y += line_spacing

def on_video(image):
    global last_image
    last_image = cudaMemcpy(image)
    if last_text and (time.time() - last_text_time) <= args.subtitle_hold_sec:
        font_text = remove_special_tokens(last_text)
        draw_subtitle(image, font_text)
    video_output(image)
    
video_source = VideoSource(**vars(args), cuda_stream=0)
video_source.add(on_video, threaded=False)
video_source.start()

video_output = VideoOutput(**vars(args))
video_output.start()

font = cudaFont()

# apply the prompts to each frame
while True:
    if last_image is None:
        time.sleep(0.005)
        continue

    now = time.time()
    if (now - last_infer_time) < args.infer_interval_sec:
        time.sleep(0.005)
        continue

    chat_history.append('user', text=f'Image {num_images + 1}:')
    chat_history.append('user', image=last_image)
    
    last_image = None
    num_images += 1

    for prompt in prompts:
        last_text = f"[{time.strftime('%H:%M:%S')}] infer..."
        last_text_time = time.time()
        chat_history.append('user', prompt)
        embedding, _ = chat_history.embed_chat()
        
        print('>>', prompt)
        
        reply = model.generate(
            embedding,
            max_new_tokens=args.max_new_tokens,
            min_new_tokens=args.min_new_tokens,
            do_sample=args.do_sample,
            repetition_penalty=args.repetition_penalty,
            temperature=args.temperature,
            top_p=args.top_p,
        )
        
        response_text = ''
        for token in reply:
            cprint(token, 'blue', end='\n\n' if reply.eos else '', flush=True)
            response_text += token

        response_text = remove_special_tokens(response_text).replace('\n', ' ').strip()
        response_text = re.sub(r'^\s*(?:\d+[\).:\-]?\s*)+', '', response_text)
        response_text = re.sub(r'\s{2,}', ' ', response_text).strip()

        max_chars = max(16, args.subtitle_max_chars)
        if len(response_text) > max_chars:
            response_text = response_text[:max_chars]
            if ' ' in response_text:
                response_text = response_text.rsplit(' ', 1)[0]
            response_text = response_text + '...'

        last_text = f"[{time.strftime('%H:%M:%S')}] {response_text}"

        last_infer_time = time.time()
        last_text_time = last_infer_time

        chat_history.append('bot', reply)
        chat_history.pop(2)
        
    if num_images >= args.max_images:
        chat_history.reset()
        num_images = 0
        
    if video_source.eos:
        video_output.stream.Close()
        break
