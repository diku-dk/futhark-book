#!/usr/bin/env python
#
# A generic visualiser for a Futhark program, using Pygame.  You can
# use this to quickly test out things by modifying the
# visualize_model.fut program, or use it as a starting point for a new
# visualization.

import visualise_model

import numpy
import pygame
import time
import sys

preferred_size = (1000,1000) # Set to None for full-screen.

# Pygame initialisation.
pygame.init()
pygame.display.set_caption('Generic Visualization')
if preferred_size != None:
    width, height = preferred_size
else:
    width = screen.get_width()
    height = screen.get_height()
size = (width, height)
print size
screen = pygame.display.set_mode(size)
surface = pygame.Surface(size)
font = pygame.font.Font(None, 36)
pygame.key.set_repeat(500, 50)

# Utility function for printing text.
def showText(what, where):
    text = font.render(what, 1, (100, 100, 255))
    screen.blit(text, where)

# Create a class instance corresponding to the Futhark program.  This
# object exposes three methods (corresponding to entry points in the
# Futhark program):
#
#  * 'initial_state', which returns some state.
#
#  * 'advance', which takes as argument a state, an integer
#    representing some setting, and returns a new state.
#
#  * 'render', which takes as arguments the size of the viewport, the
#    state, the setting, and returns an array of pixel data to be
#    blitted to the screen.
#
# If you create new programs whose state is a tuple, you will need to
# modify these to accept more parameters.
model = visualise_model.visualise_model()

state = model.initial_state()

# This variable is modified on the Python side in response to keyboard input.
setting = 10

def render(model_time):
    start = time.time()
    # The .get() is necessary to retrieve a CPU-side Numpy array, as
    # expected by the blit_array() method we use below.  It is likely
    # that most of the time is spent copying this array back to main
    # memory (only to then push it back to the GPU for rendering...).
    frame = model.render(width, height, state, setting).get()
    end = time.time()
    render_time = (end - start) * 1000

    pygame.surfarray.blit_array(surface, frame)
    screen.blit(surface, (0, 0))

    message = "Advancing took %.2fms; rendering took %.2fms (state setting: %d)" % (model_time, render_time, setting)
    showText(message, (10,10))

    pygame.display.flip()

while True:
    # First, advance the state of our model.  Measure how long that takes.
    start = time.time()
    state = model.advance(state, setting)
    end = time.time()

    # Then visualise it.
    render((end - start) * 1000)

    # Now wait for and handle events.
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            # Our window was closed.
            sys.exit()
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_UP:
                setting += 1
            if event.key == pygame.K_DOWN:
                setting -= 1
