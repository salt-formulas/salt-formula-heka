# -*- coding: utf-8 -*-

import re

_valid_dimension_re = re.compile(r'^[a-z0-9_/-]+$')
_disallowed_dimensions = ('name', 'value', 'hostname', 'member',
                          'no_alerting', 'tag_fields')


def message_matcher(alarm, triggers):
    """
    Return an Heka message matcher expression for a given alarm and a
    dict of triggers.

    For example the function may return this:

        Fields[name] == 'cpu_idle' || Fields[name] = 'cpu_wait'
    """
    matchers = set()
    for trigger_name in alarm.get('triggers', []):
        trigger = triggers.get(trigger_name)
        if trigger and trigger.get('enabled', True):
            for rule in trigger.get('rules', []):
                matcher = "Fields[name] == '{}'".format(rule['metric'])
                matchers.add(matcher)
    return ' || '.join(matchers)


def dimensions(alarm):
    """
    Return a dict alarm dimensions. Each dimension is validated, and an
    Exception is raised if a dimension is invalid.

    Valid characters are a-z, 0-9, _, - and /.
    """
    dimensions = alarm.get('dimension', {})
    for name, value in dimensions.items():
        if name in _disallowed_dimensions:
            raise Exception(
                '{} is not allowed as a dimension name'.format(name))
        if not _valid_dimension_re.match(name):
            raise Exception(
                'Dimension name {} includes disallowed chars'.format(name))
        if not _valid_dimension_re.match(value):
            raise Exception(
                'Dimension value {} includes disallowed chars'.format(value))
    return dimensions
