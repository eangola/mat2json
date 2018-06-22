#!/usr/bin/env python
"""
Created : 21-06-2018
Last Modified : Fri 22 Jun 2018 06:46:45 PM EDT
Created By : Enrique D. Angola
"""

import json

import scipy.io as spio
import pandas as pd

def loadmat(filename):
    '''
    this function should be called instead of direct spio.loadmat
    as it cures the problem of not properly recovering python dictionaries
    from mat files. It calls the function check keys to cure all entries
    which are still mat-objects
    '''
    data = spio.loadmat(filename, struct_as_record=False, squeeze_me=True)
    return _check_keys(data)

def _check_keys(dict):
    '''
    checks if entries in dictionary are mat-objects. If yes
    todict is called to change them to nested dictionaries
    '''
    for key in dict:
        if isinstance(dict[key], spio.matlab.mio5_params.mat_struct):
            dict[key] = _todict(dict[key])
    return dict

def _todict(matobj):
    '''
    A recursive function which constructs from matobjects nested dictionaries
    '''
    dict = {}
    for strg in matobj._fieldnames:
        elem = matobj.__dict__[strg]
        if isinstance(elem, spio.matlab.mio5_params.mat_struct):
            dict[strg] = _todict(elem)
        else:
            dict[strg] = elem
    return dict

def mat2json(filename=None,filepath = ''):
    """
    Converts .mat file to .json and writes new file

    Parameters
    ----------
    filename: Str
        path/filename of .mat file
    filepath: Str
        path to write converted file

    Returns
    -------
    None

    Examples
    --------
    >>> mat2json(blah blah)

    """

    matlabFile = loadmat(filename)
    #pop all those dumb fields that don't let you jsonize file
    matlabFile.pop('__header__')
    matlabFile.pop('__version__')
    matlabFile.pop('__globals__')
    #jsonize the file - orientation is 'index'
    matlabFile = pd.Series(matlabFile).to_json()
    with open(filepath+filename[0:-4]+'.json','w') as f:
        f.write(matlabFile)

def parse_args(args):
    """
    parse arguments from command line

    Parameters
    ----------
    args: list
        list of raw arguments from command line

    Returns
    -------
    args: dictionary
        parsed arguments

    """

    parser = argparse.ArgumentParser(description='A portable UNIX executable\
            for performing bandit selection. This process reads a history \
            file and records the next arm to be plated to that history file')
    parser.add_argument('algorithm', type = str, help = 'choice of bandit \
            selection algorithm. Must be "eps-first greedy" or "eps greedy", \
            exacttly.')
    parser.add_argument('historyfile', type = str, help = 'a csv file in the \
            current working directory that stores the history of the current \
            gamble. the ID of the next arm to play is appended to this file; \
            another process will then add the reward for that play.')
    parser.add_argument('N', type = int, help = 'an integer > 1, the number \
            of arms the bandit has, with arm IDs 0, 1, ..., N-1')

    args = parser.parse_args(args)
    return args

def main(args):
    """
    Takes parsed arguments and runs the program

    Parameters
    ----------
    args: dictionary
        parsed arguments

    Returns
    -------
    None

    """

    data = read_csv(args.historyfile)
    b = Bandit(arms=args.N,preData=data)
    arm2play = b.gamble(method=args.algorithm)
    write_csv(filename=args.historyfile,arm2play=arm2play)


if __name__ == '__main__':

    args = parse_args(sys.argv[1:])
    main(args)

