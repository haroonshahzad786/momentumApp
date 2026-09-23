import { AxiosRequestConfig } from 'axios'

export interface AxiosRequest {
  method: AxiosRequestConfig['method']
  url: string
  token?: string
  data?: any
}
