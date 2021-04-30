# Wakey-Wakey

![Wakey-Wakey Logo](./img/logo.png)

## A Low-Power Reconfigurable Wake Word Accelerator

## Special Note for 2021-04-30 RTL Submission:

TODO:
- Completed a full custom DNN accelerator! ANd verified
- Have functional models for our featurization pipeline
- We're actively developing our DFE because we are doing this on a real HW dev
  Vesper mic arrives 2 days ago.
- CFG - Wishbone from Caravel, trivial.
- Our RTL not fully finished but our design is all standard cells, on track for
  tapeout since PD is easy and we've done it already.

For your code submission deadline tomorrow please submit a document on canvas
with the commit hash we should look at in your code repository. At this commit
in your repo you should have:

1. A document in the repo listing all your blocks and a list of tests you ran on
   each block and at the top level.

    Please see `rtl/ARCHITECTURE.md` for a listing of all of our blocks and
    corresponding tests.

2. For analog blocks that were verified based on a plot, you should 1) provide
   all the scripts needed to reproduce that plot, 2) provide an image of what
   the plot should look like, 3) report what specs you verified with that plot.

    N/A - our design contains no analog blocks.

3. For digital blocks you should provide the scripts/makefiles to run each test,
   and document how we can replicate them. All tests must check the simulation
   versus a gold output, and print a PASS/FAIL status at the end.

    Please see `rtl/README.md` for instructions on running and interpreting
    our tests.

4. For all projects, a summary of the key design metrics you achieved and how
   they compare to your initial targets (similar to how you presented in your
   design reviews).

    Please see `pd/README.md` for a summary of our key design metrics.

We will grade your submission based on:

    Completeness of your design

    Whether we are able to run your tests and replicate your results

    How good/comprehensive your the tests are

    Quality of your documentation (all documentation should be in the repo)


## Table of Contents

- [Overview](#overview)
- [References](#references)
- [Architecture](#architecture)
- [Contributors](#contributors)


## Overview

Wakey-Wakey is being built in Stanford University's EE272B: Design Projects in
VLSI Systems II.

It is expected to be submitted for tapeout in June 2021 as part of
Skywater Foundry's SKY130 MPW-TWO shuttle program.

Packaged die are expected to be received by December 2021.

### Structure
The project is structured as follows:

- `img` contains images for use in documentation throughout the project

- `py` contains software models in Python for our acoustic featurization
   pipeline and DNN accelerator

- `rtl` contains RTL source files and associated testbenches. Further details on
   RTL architecture and running the testbenches can be found in this repo.

## Architecture

![Wakey-Wakey High Level Block Diagram](./img/overview.png)


## References

[Project Proposal](https://docs.google.com/document/d/17Ahc0jS1TsNaqgZagLtGwdKn3h2x0l6fPzC-cuKEdq0/edit?usp=sharing)


## Contributors
- [Eldrick Millares (@eldrickm)](https://github.com/eldrickm)
- [Matthew Pauly (@mjpauly)](https://github.com/mjpauly)
