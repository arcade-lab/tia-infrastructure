"""
Utilities for manipulating parameters objects.
"""

import json

import yaml

from parameters.core_parameters import CoreParameters
from parameters.interconnect_parameters import InterconnectParameters
from parameters.system_parameters import SystemParameters


def build_parameters_from_json(parameters_json_string):
    """
    Parse JSON parameters into custom parameter types.

    :param parameters_json_string: string form of JSON configuration
    :return: a three-tuple of core, interconnect and system parameters
    """

    # Parse the JSON and build and return each type.
    parameters_dictionary = json.loads(parameters_json_string)
    cp = CoreParameters.from_dictionary(parameters_dictionary["core"])
    ip = InterconnectParameters.from_dictionary(parameters_dictionary["interconnect"])
    sp = SystemParameters.from_dictionary(parameters_dictionary["system"])
    return cp, ip, sp


def build_parameters_from_yaml(parameters_yaml_string):
    """
    Parse YAML parameters into custom parameter types.
    
    :param parameters_yaml_string: string form of YAML configuration
    :return: a three-tuple of core, interconnect and system parameters
    """

    # Parse the YAML and build and return each type.
    parameters_dictionary = yaml.load(parameters_yaml_string)
    cp = CoreParameters.from_dictionary(parameters_dictionary["core"])
    ip = InterconnectParameters.from_dictionary(parameters_dictionary["interconnect"])
    sp = SystemParameters.from_dictionary(parameters_dictionary["system"])
    return cp, ip, sp
