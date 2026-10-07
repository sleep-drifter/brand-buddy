# Third-party licenses

Portions of DesignerBuddy are ported from or inspired by open-source work.
This file carries the required license notices. (The Shadertoy ports
Seascape, Protean Clouds, and Plasma Globe are CC BY-NC-SA 3.0 and are used
only inside the non-commercial playground catalog — they are deliberately
excluded from Oscilla patches and from any commercial surface; see
OSCILLA.md.)

## my-toybox — MIT License

Ported code: the stable-fluid GPU solver (`StableFluidKernels.metal`,
`StableFluidView.swift`), SDF playgrounds (`SDFShaders.metal`,
`SDFPlaygrounds.swift`), layout playgrounds, Lissajous curve, implicit
equation, flow distortion, physics tag, and the Canvas metaball technique.

```
MIT License

Copyright (c) 2025 takehito

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

(https://github.com/Koshimizu-Takehito/my-toybox — the fluid solver there in
turn credits Jos Stam, "Stable Fluids," SIGGRAPH 1999 — an algorithm, not
copyrightable expression — and TypeGPU below.)

## TypeGPU — MIT License

The stable-fluid Metal implementation is inspired by TypeGPU's stable-fluid
example.

```
MIT License

Copyright (c) 2025 Software Mansion

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

(https://github.com/software-mansion/TypeGPU)

## Inferno — MIT License

Several playground shaders (`shaderSinebow`, `shaderLightGrid`,
`shaderShimmer`, `shaderInfrared`, and others noted in
`ShadersPlayground.metal`) are ports of Paul Hudson's Inferno shader
collection, MIT License, Copyright (c) Paul Hudson
(https://github.com/twostraws/Inferno). The standard MIT terms above apply
with that copyright line.

## Star Nest — MIT License

`shaderStarNest` (`ShadertoyClassics.metal`) is a port of "Star Nest" by
Pablo Roman Andrioli ("Kali"), MIT License. The standard MIT terms above
apply with that copyright line.
