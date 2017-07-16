import collections

from av.utils cimport err_check, encode_string, decode_string


cdef class _Dictionary(object):

    def __cinit__(self, *args, **kwargs):
        for arg in args:
            self.update(arg)
        if kwargs:
            self.update(kwargs)

    def __dealloc__(self):
        if self.ptr != NULL:
            lib.av_dict_free(&self.ptr)

    def __getitem__(self, str key):
        _key = encode_string(key)     # convert unicode -> byte
        cdef lib.AVDictionaryEntry *element = lib.av_dict_get(self.ptr, _key, NULL, 0)
        if element != NULL:
            _value = decode_string(element.value)   # convert byte -> unicode
            return _value
        else:
            raise KeyError(_key)

    def __setitem__(self, str key, str value):
        _key = encode_string(key)     # convert unicode -> byte
        _value = encode_string(value)     # convert unicode -> byte
        err_check(lib.av_dict_set(&self.ptr, _key, _value, 0))

    def __delitem__(self, str key):
        _key = encode_string(key)     # convert unicode -> byte
        err_check(lib.av_dict_set(&self.ptr, _key, NULL, 0))

    def __len__(self):
        return err_check(lib.av_dict_count(self.ptr))

    def __iter__(self):
        cdef lib.AVDictionaryEntry *element = NULL
        while True:
            element = lib.av_dict_get(self.ptr, "", element, lib.AV_DICT_IGNORE_SUFFIX)
            if element == NULL:
                break
            _key = decode_string(element.key)   # convert byte -> unicode
            yield _key

    def __repr__(self):
        return 'av.Dictionary(%r)' % dict(self)

    cpdef _Dictionary copy(self):
        cdef _Dictionary other = Dictionary()
        lib.av_dict_copy(&other.ptr, self.ptr, 0)
        return other


class Dictionary(_Dictionary, collections.MutableMapping):
    pass


cdef _Dictionary wrap_dictionary(lib.AVDictionary *input_):
    cdef _Dictionary output = Dictionary()
    output.ptr = input_
    return output
