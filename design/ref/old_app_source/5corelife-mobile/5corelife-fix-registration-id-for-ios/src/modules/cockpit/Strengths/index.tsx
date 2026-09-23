import React, { useEffect, useState } from 'react'
import {
  Animated, Easing
} from 'react-native'
import { useRecoilState, useRecoilValue } from 'recoil'
import Cockpit from '../../../components/Cockpit'
import CockpitListItemSelect from '../../../components/CockpitListItemSelect'
import { URL } from '../../../helpers/api'
import { fetchAxios } from '../../../helpers/axios'
import { vh } from '../../../helpers/dimensions'
import { setAtomAxios } from '../../../helpers/recoil'
import { strengthsAtom, inspirationsAtom, storageAtom } from '../../../recoil/atoms'
import { CockpitList, CockpitListRequest, Strength } from '../../../typescript/main'
import props from './props'
import strings from './strings'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { goBack } }: props) => {
  const {
    value: { token }
  } = useRecoilValue(storageAtom)

  const inspirations = useRecoilValue(inspirationsAtom)
  const [items, setItems] = useRecoilState<any>(strengthsAtom)

  const [data, setData] = useState<any[]>([])
  const [itemsState, setItemsState] = useState<Strength[] | null>([])
  const [itemsStregths, setItemsStregths] = useState<Strength | null>(null)
  const [screenPosY] = useState(new Animated.Value(0))

  useEffect(() => {
    (async () => {
      const cockpitList = await fetchAxios<null, CockpitList[]>(
        'GET',
        URL + 'cockpit-list/',
        token,
        null
      )
      let filter = cockpitList.filter((response: CockpitList) => response.name === strings.TITLE)
      setData(filter)
    })()
  }, [])

  useEffect(() => {
    if (data.length) {
      setAtomAxios(setItems, {
        method: 'GET',
        url: URL + `cockpit-list/${data[0]?.id}/`
      })
    }
  }, [setItems, data])

  useEffect(() => {
    setItemsState(items?.value?.items ? JSON.parse(items?.value?.items) : [])
  }, [setItemsState, items.value])

  useEffect(() => {
    Animated.timing(screenPosY, {
      toValue: vh(21.5),
      easing: Easing.out(Easing.ease),
      duration: 1500,
      useNativeDriver: true
    }).start()
  }, [screenPosY])

  const updateFearsState = (index: number, text: string) => {
    let newFearsState: Strength[] = JSON.parse(JSON.stringify(itemsState))
    newFearsState[index].name = text
    setItemsState(newFearsState)
  }

  const addItemStregths = (text: string) => {
    setItemsStregths({
      id: 0,
      name: text,
      category: '',
    })
  }

  const saveEverything = async () => {
    try {
      const items: CockpitListRequest = {
        name: strings.TITLE,
        items: JSON.stringify(itemsState)
      }
      await fetchAxios<CockpitListRequest, CockpitList>(
        'PUT',
        URL + `cockpit-list/${data[0]?.id}/`,
        token,
        items
      )
      goBack()
    } catch (error: any) {
      logger.error('Cockpit Strengths error: ', error.response);
    }
  }

  const handleAdd = (value: any) => {
    setItemsState([
      ...itemsState!,
      value,
    ])
  }

  return (
    <>
      <Cockpit>
        <CockpitListItemSelect
          data={itemsState}
          goBack={goBack}
          inspirations={inspirations}
          onAdd={handleAdd}
          styleBack={{}}
          addItemCockpit={addItemStregths}
          itemsCockpit={itemsStregths}
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
