import os
import pathlib
from scipy.io import wavfile
import speechpy
import numpy as np


cache_dir = pathlib.Path(__file__).parent.absolute()
cache_fnames = ['x_train.npy', 'y_train.npy', 'x_test.npy', 'y_test.npy']


def cache_features():
    # download and unzip keywords dataset
    zip_fname = str(cache_dir / 'keywords2.zip')
    os.system('curl https://cdn.edgeimpulse.com/datasets/keywords2.zip -o ' + zip_fname)
    os.system('unzip ' + zip_fname + ' -d ' + str(cache_dir))

    train_test_split = 0.75  # fraction to have as training data

    # parameters
    p = {'num_mfcc_cof': 13,
         'frame_length': 0.02,
         'frame_stride': 0.02,
         'filter_num': 32,
         'fft_length': 256,
         'window_size': 101,
         'low_frequency': 300,
         'preemph_cof': 0.98}

    def get_features(fullfname):
        '''Reads a .wav file and outputs the MFCC features.'''
        try:
            fs, data = wavfile.read(fullfname)
        except ValueError:
            print('failed to read file {}, continuing'.format(fullfname))
            return np.zeros(650)

        # generate features
        preemphasized = speechpy.processing.preemphasis(data, cof=p['preemph_cof'], shift=1)
        mfcc = speechpy.feature.mfcc(preemphasized, fs, frame_length=p['frame_length'],
                                      frame_stride=p['frame_stride'], num_cepstral=p['num_mfcc_cof'],
                                      num_filters=p['filter_num'], fft_length=p['fft_length'],
                                      low_frequency=p['low_frequency'])
        #print('mfcc shape', mfcc.shape)
        # TODO: Why is the output shape here (49, 13) and not (50, 13)?
        # For now just repeat last frame:
        mfcc2 = np.zeros((50, 13))
        mfcc2[:-1,:] = mfcc
        mfcc2[-1,:] = mfcc[-1,:]

        mfcc_cmvn = speechpy.processing.cmvnw(mfcc2, win_size=p['window_size'], variance_normalization=True)

        flattened = mfcc_cmvn.flatten()
        return flattened

    def get_fnames(group):
        '''Gets all the filenames (with directories) for a given class.'''
        group_dir = cache_dir / group
        fnames = os.listdir(group_dir)
        fnames = [x for x in fnames if not x.startswith('.')]  # ignore .DS_Store
        fullnames = [group_dir / fname for fname in fnames]
        return fullnames

    # collect a big list of filenames and a big list of labels
    all_fnames = []
    all_labels = []
    for group in ['yes', 'unknown', 'noise']:
        fnames = get_fnames(group)
        label = 1 if group == 'yes' else 2
        repeat = 2 if group == 'yes' else 1  # oversample wake word class 2x to balance dataset
        for _ in range(repeat):
            all_fnames.extend(fnames)
            for i in range(len(fnames)):
                all_labels.append(label)

    # get a big list of mfcc features
    n = len(all_fnames)
    print('num samples: ', n)
    all_features = np.zeros((0, 13*50))
    for fname in all_fnames:
        features = get_features(fname)
        all_features = np.vstack((all_features, features))
    all_labels = np.array(all_labels)

    # shuffle the data randomly
    idx = np.arange(n, dtype=int)
    np.random.shuffle(idx)
    features_shuffled = all_features[idx,:]
    labels_shuffled = all_labels[idx]

    # split the data into train and test sets
    split = int(train_test_split * n)
    X = features_shuffled[:split,:]
    Y = labels_shuffled[:split]
    Xtest = features_shuffled[split:,:]
    Ytest = labels_shuffled[split:]

    data = [X, Y, Xtest, Ytest]
    for i in range(4):
        fname = cache_dir / cache_fnames[i]
        with open(fname, 'wb') as f:
            np.save(f, data[i])

    return X, Y, Xtest, Ytest


def load_npy(fname):
    with open(fname, 'rb') as f:
        return np.load(f)


if not os.path.exists(cache_dir / cache_fnames[0]):
    X, Y, Xtest, Ytest = cache_features()
else:
    X = load_npy(cache_dir / cache_fnames[0])
    Y = load_npy(cache_dir / cache_fnames[1])
    Xtest = load_npy(cache_dir / cache_fnames[2])
    Ytest = load_npy(cache_dir / cache_fnames[3])
