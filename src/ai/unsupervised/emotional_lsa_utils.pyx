import numpy as np
cimport numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from cython.parallel import parallel, prange


def _normalization(x, int a, int b):
    return (2 * b) * (x - np.min(x)) / np.ptp(x) + a


def _transform(wv, V, dict emotion_words, int _ldocs):
    cdef int i
    cdef int k
    cdef int size
    cdef int e_size

    size = _ldocs + 2
    e_size = len(emotion_words.keys())
    dtframe = np.ones((size, e_size))
    for i in range(_ldocs):
        for k in range(e_size):
            a = [wv[:, k]]
            b = [V.T[i]]
            dtframe[i][k] = cosine_similarity(a, b)
        mmax, mmin = np.max(dtframe[i]), np.min(dtframe[i])
        if abs(mmin) > mmax:
            dtframe[i] = -dtframe[i]
    dtframe[size-1] = np.tile([-1], e_size)
    return np.round(_normalization(dtframe, -100, 100), 2)[:size-2, :]


cdef np.ndarray _calculate_sentiment_weights(list words, int dims, np.ndarray U, np.ndarray weights, dict idx):
    cdef int i
    cdef char* value
    cdef np.ndarray[np.int_t, ndim=1] wv = np.zeros((dims))

    for value in words:
        for i in range(dims):
            indexes = filter(None, [e if value in inx else None for e, inx in enumerate(idx.keys())])
            wv[i] += sum([sum(U[index][i] * weights.iloc[index].values[i]) for index in indexes])
    return wv / dims


cdef np.ndarray _calculate_emotional_state(np.ndarray u, dict idx, dict emotion_words, np.ndarray weights, int dims):
    cdef int k
    cdef int i
    cdef list values
    cdef char* value
    cdef np.ndarray[np.int_t, ndim=2] wv = np.zeros((dims, len(emotion_words.keys())))

    for k, values in enumerate(emotion_words.values()):
        for value in values:
            for i in range(dims):
                indexes = filter(None, [e if value in inx else None for e, inx in enumerate(idx.keys())])
                wv[i][k] += np.sum([u[index][i] * weights.iloc[index].values[i] for index in indexes])
    return wv / dims
