import { SetterOrUpdater } from 'recoil'

import { AxiosRequest } from '../typescript/axios'
import { logger } from './logger';

export const setAtomAxios = (
  setAtom: SetterOrUpdater<any>,
  axiosRequest: AxiosRequest,
  cachedValue?: any
) => {
  const atom = {
    init: true,
    isLoading: true,
    request: axiosRequest,
    value: cachedValue ? cachedValue : null,
    error: null
  }
  logger.debug('helpers.recoil.SetAtomAxios axiosRequest token: ' + axiosRequest.token);
  logger.debug('url: ' + axiosRequest.url);
  logger.debug('cacheValue: ' + cachedValue);
  logger.debug('atom: ' + JSON.stringify(atom));

  setAtom(atom)
}

export const setAtomManual = (setAtom: SetterOrUpdater<any>, value: any) => {
  const atom = {
    init: true,
    isLoading: false,
    request: null,
    value,
    error: null
  }

  setAtom(atom)
}
