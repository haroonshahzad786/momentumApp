import React, { useEffect, useState } from 'react'
import {
  Animated, Easing,
} from 'react-native'
import { useRecoilState, useRecoilValue } from 'recoil'
import Cockpit from '../../../components/Cockpit'
import CockpitListItemSelect from '../../../components/CockpitListItemSelect'
import { URL } from '../../../helpers/api'
import { fetchAxios } from '../../../helpers/axios'
import { vh } from '../../../helpers/dimensions'
import { setAtomAxios } from '../../../helpers/recoil'
import { fearsAtom, inspirationsAtom, storageAtom } from '../../../recoil/atoms'
import { CockpitList, CockpitListRequest, Fear } from '../../../typescript/main'
import props from './props'
import strings from './strings'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { goBack }, route: { params } }: props) => {
  const {
    value: { token }
  } = useRecoilValue(storageAtom)

  const inspirations = useRecoilValue(inspirationsAtom)
  const [fears, setFears] = useRecoilState<any>(fearsAtom)

  const [data, setData] = useState<any[]>([])
  const [fearsState, setFearsState] = useState<Fear[] | null>([])
  const [itemsFear, setItemsFear] = useState<Fear | null>(null)
  const [screenPosY] = useState(new Animated.Value(0))

  useEffect(() => {
    (async () => {
      const api = await fetchAxios<null, CockpitList[]>(
        'GET',
        URL + 'cockpit-list/',
        token,
        null
      )
      let filter = api.filter((response: any) => response.name === strings.TITLE)
      setData(filter)
    })()
  }, [])

  useEffect(() => {
    if (data.length) {
      setAtomAxios(setFears, {
        method: 'GET',
        url: URL + `cockpit-list/${data[0]?.id}/`
      })
    }
  }, [setFears, data])

  useEffect(() => {
    setFearsState(fears?.value?.items ? JSON.parse(fears?.value?.items) : [])
  }, [setFearsState, fears.value])

  useEffect(() => {
    Animated.timing(screenPosY, {
      toValue: vh(21.5),
      easing: Easing.out(Easing.ease),
      duration: 1500,
      useNativeDriver: true
    }).start()
  }, [screenPosY])

  const updateFearsState = (index: number, text: string) => {
    let newFearsState: Fear[] = JSON.parse(JSON.stringify(fearsState))
    newFearsState[index].name = text
    setFearsState(newFearsState)
  }

  const addItemFears = (text: string, core: string) => {
    setItemsFear({
      id: 0,
      name: text,
      category: '',
    })
  }

  const saveEverything = async () => {
    try {
      const items: CockpitListRequest = {
        name: strings.TITLE,
        items: JSON.stringify(fearsState)
      }
      await fetchAxios<CockpitListRequest, CockpitList>(
        'PUT',
        URL + `cockpit-list/${data[0]?.id}/`,
        token,
        items
      )
      goBack()
    } catch (error: any) {
      logger.error('CockpitList update error: ', error.response);
    }
  }

  const handleAdd = (value: any) => {
    setFearsState([
      ...fearsState!,
      value
    ]);
  }

  return (
    <>
      <Cockpit>
        <CockpitListItemSelect
          data={fearsState}
          goBack={goBack}
          inspirations={inspirations}
          onAdd={handleAdd}
          styleBack={{}}
          addItemCockpit={addItemFears}
          itemsCockpit={itemsFear}
          saveEverything={saveEverything}
          screenPosY={screenPosY}
          title={data[0]?.name}
          textSelector={(x: any) => { return x.name }}
          textModal={strings.ADD_ITEM}
          textScreen={data[0]?.description}
          items={data[0]?.options}
        />
      </Cockpit>
    </>
  )
}
