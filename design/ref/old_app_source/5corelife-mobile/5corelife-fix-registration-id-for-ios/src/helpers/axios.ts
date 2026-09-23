import axios, { AxiosRequestConfig, AxiosResponse } from 'axios'
import { setupCache } from 'axios-cache-adapter'

import { AxiosRequest } from '../typescript/axios'
import { logger } from './logger';

const cache = setupCache({
  maxAge: 15 * 60 * 1000
})

const api = axios.create({
  adapter: cache.adapter
});

export const fetchTextAxios = async ({
  method,
  url,
  token,
  data
}: AxiosRequest) => {
  const request: AxiosRequestConfig = {
    method: method,
    headers: token
      ? { Authorization: `Token ${token}`, 'Content-Type': 'application/json' }
      : { 'Content-Type': 'application/json' },
    url,
    data: data || null,
    responseType: 'text'
  };
  const response = await api(request);
  return response.data
}

export const fetchAxios = async<RequestType, ResponseType>(
  method: AxiosRequestConfig['method'],
  url: string,
  token: string | null,
  data: RequestType | null
): Promise<ResponseType> => {
  const request: AxiosRequestConfig = {
    method: method,
    headers: token
      ? { Authorization: `Token ${token}`, 'Content-Type': 'application/json' }
      : { 'Content-Type': 'application/json' },
    url,
    data: data || null,
    responseType: 'json'
  };

  try {
    const response: AxiosResponse<ResponseType> = await api(request);
    return response.data;
  } catch (error) {
    logger.debug('fetchAxios with error: ' + JSON.stringify(error));
    throw error;
  }
}

export const fetchAxiosNoCache = async<RequestType, ResponseType> (
  method: AxiosRequestConfig['method'],
  url: string,
  token: string | null,
  data: RequestType | null
): Promise<ResponseType> => {
  const request: AxiosRequestConfig = {
    method: method,
    headers: token
      ? { Authorization: `Token ${token}`, 'Content-Type': 'application/json' }
      : { 'Content-Type': 'application/json' },
    url,
    data: data || null,
    responseType: 'json'
  };

  try {
    const response: AxiosResponse<ResponseType> = await axios(request);
    return response.data;
  } catch (error) {
    logger.debug('fetchAxiosNoCache with error: ' + JSON.stringify(error));
    throw error;
  }
}

export const fetchAxiosMultiple = async (
  requests: (AxiosRequest | undefined)[]
) => {
  const cleanRequests: AxiosRequest[] = requests.filter(
    (x) => x !== undefined && x !== null
  ) as AxiosRequest[]
  return axios
    .all(
      cleanRequests.map(({ method, url, token, data }) => {
        const request: AxiosRequestConfig =  {
          method: method,
          headers: token
            ? {
                Authorization: `Token ${token}`,
                'Content-Type': 'application/json'
              }
            : { 'Content-Type': 'application/json' },
          url,
          data: data || null,
          responseType: 'json'
        };
        return api(request);
      }
      )
    )
    .then(
      axios.spread((...responses) => responses.map((response) => response.data))
    )
}
