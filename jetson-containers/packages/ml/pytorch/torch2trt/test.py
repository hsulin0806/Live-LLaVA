#!/usr/bin/env python3
print('testing torch2trt...')

import sys
import torch
from torch2trt import torch2trt
from torchvision.models.alexnet import alexnet

# create some regular pytorch model...
model = alexnet(pretrained=True).eval().cuda()

# create example data
x = torch.ones((1, 3, 224, 224)).cuda()

try:
    # convert to TensorRT feeding sample data as input
    model_trt = torch2trt(model, [x])

    # execute the returned TRTModule like the original PyTorch model
    y = model(x)
    y_trt = model_trt(x)

    # check the output against PyTorch
    print(torch.max(torch.abs(y - y_trt)))
    print('torch2trt OK\n')
except Exception as e:
    msg = str(e)
    if 'factory function returned nullptr' in msg or 'libnvinfer_builder_resource' in msg:
        print(f'torch2trt runtime unavailable on this image, skipping test: {e}')
        sys.exit(0)
    raise
