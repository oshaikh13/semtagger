#!/usr/bin/python3
# this script provides mappings from strings to various Keras objects

from keras import optimizers
from keras import losses


def get_optimizer(label):
    """
    Obtains a Keras optimizer from a string with its default parameters
        Inputs:
            - label: string representation of the optimizer
        Output:
            - optimizer as Keras object
    """
    if label == "sgd":
        return optimizers.SGD(lr=0.01, momentum=0.0, decay=0.0, nesterov=True)
    if label == "rmsprop":
        return optimizers.RMSprop(lr=0.001, rho=0.9, epsilon=None, decay=0.0)
    if label == "adam":
        return optimizers.Adam(lr=0.001, beta_1=0.9, beta_2=0.999, epsilon=None, decay=0.0, amsgrad=False)
    if label == 'adamax':
        return optimizers.Adamax(lr=0.002, beta_1=0.9, beta_2=0.999, epsilon=None, decay=0.0)
    if label == 'nadam':
        return optimizers.Nadam(lr=0.002, beta_1=0.9, beta_2=0.999, epsilon=None, schedule_decay=0.004)
    return None


def get_loss(label):
    """
    Obtains a Keras loss from a string
        Inputs:
            - label: string representation of the loss
        Output:
            - loss as a Keras object
    """
    if label == "mean_squared_error":
        return losses.mean_squared_error
    if label == "mean_absolute_error":
        return losses.mean_absolute_error
    if label == "categorical_hinge":
        return losses.categorical_hinge
    if label == 'categorical_cross_entropy':
        return losses.categorical_crossentropy
    return None

