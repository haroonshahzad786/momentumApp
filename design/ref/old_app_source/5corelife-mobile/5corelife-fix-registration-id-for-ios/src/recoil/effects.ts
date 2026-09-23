import { fetchAxios, fetchAxiosNoCache } from '../helpers/axios'
import { getStorageData, setStorageData } from '../helpers/storage'
import { AtomLoadable } from '../typescript/recoil'

// Variables that are communicated between effects.
let token: string

export const loggingEffect = (atomName: string) => ({ onSet }: any) => {
  onSet(async (newValue: any, oldValue: any) => {
    console.debug('<===== LOG =====>')
    console.debug('atomName:', atomName)
    console.debug('oldValue:', oldValue)
    console.debug('newValue:', newValue)
    console.debug('<===== LOG =====>\n')
  })
}

export const storageEffect = (key: string, defaultValue?: any) => ({
  setSelf,
  onSet,
}: any) => {
  getStorageData(key).then((storageData) => {
    if (storageData) {
      if (key === 'storageAtom') {
        token = storageData.value.token
      }

      setSelf({ ...storageData, init: true })
    } else {
      setSelf({ value: defaultValue, init: true })
    }
  })

  onSet((newValue: any) => {
    setStorageData(key, newValue)
  })
}

export const axiosAtomEffect = (key: string) => ({ onSet, setSelf }: any) => {
  onSet(async (newValue: AtomLoadable<any, any>) => {
    if (newValue.request) {
      const { request } = newValue
      const { method, url, data } = request
      try {
        const response = await fetchAxios(
          method,
          url,
          token,
          method !== 'GET' ? data : null,
        );
        setSelf({
          init: true,
          isLoading: false,
          request: null,
          value: response,
          error: null,
        })

        switch (key) {
          case 'userAtom':
            if (response && response.access_token) {
              token = response.access_token
            }
            break

          case 'logoutAtom':
            if (response) {
              token = ''
            }
            break

          default:
            break
        }
      } catch (error) {
        setSelf({
          init: true,
          isLoading: false,
          request: null,
          value: null,
          error,
        })
      }
    }
  })
}

export const axiosAtomEffectNoCache = (key: string) => ({
  onSet,
  setSelf,
}: any) => {
  onSet(async (newValue: AtomLoadable<any, any>) => {
    if (newValue.request) {
      const { request } = newValue
      const { method, url, data } = request
      try {
        const response = await fetchAxiosNoCache(
          method,
          url,
          token,
          method !== 'GET' ? data : null,
        )

        setSelf({
          init: true,
          isLoading: false,
          request: null,
          value: response,
          error: null,
        })

        switch (key) {
          case 'userAtom':
            if (response && response.access_token) {
              token = response.access_token
            }
            break

          case 'logoutAtom':
            if (response) {
              token = ''
            }
            break

          default:
            break
        }
      } catch (error) {
        setSelf({
          init: true,
          isLoading: false,
          request: null,
          value: null,
          error,
        })
      }
    }
  })
}
