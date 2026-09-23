import React, { useEffect, useState } from 'react'
import {
  Animated, Easing
} from 'react-native'
import { useRecoilState, useRecoilValue } from 'recoil'
import Cockpit from '../../../components/Cockpit'
import CockpitListItemsOrder from '../../../components/CockpitListItemsOrder'
import { URL } from '../../../helpers/api'
import { fetchAxios } from '../../../helpers/axios'
import { vh } from '../../../helpers/dimensions'
import { setAtomAxios } from '../../../helpers/recoil'
import { inspirationsAtom, messesAtom, storageAtom } from '../../../recoil/atoms'
import { CockpitList, CockpitListRequest, Messes } from '../../../typescript/main'
import props from './props'
import strings from './strings'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { goBack } }: props) => {
  const {
    value: { token }
  } = useRecoilValue(storageAtom)

  const inspirations = useRecoilValue(inspirationsAtom)
  const [items, setItems] = useRecoilState<any>(messesAtom)

  const [data, setData] = useState<any[]>([])
  const [itemsState, setItemsState] = useState<Messes[] | null>([])
  const [itemsMesses, setItemsMesses] = useState<Messes | null>(null)
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

  const addItemPassions = (text: string) => {
    setItemsMesses({
      id: currentId(),
      name: text,
      user: 0,
      order: 0,
      new: true
    })
  }

  const currentId = () => {
    if (itemsState && itemsState?.length > 0) {
      let max = itemsState.reduce((stack: any, { id }: any) => Math.max(stack, id), -Number.POSITIVE_INFINITY)
      return max + 1;
    }
    return 0;
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
      logger.error('Cockpit Messes error: ', error.response);
    }
  }

  const handleAdd = (value: any) => {
    setItemsState([
      ...itemsState!,
      value
    ])
  }

  const handleArray = (data: any[]) => setItemsState([...data])

  return (
    <>
      <Cockpit>
        <CockpitListItemsOrder
          data={itemsState}
          goBack={goBack}
          inspirations={inspirations}
          onAdd={handleAdd}
          handleArray={handleArray}
          styleBack={{ marginRight: 12 }}
          addItemCockpit={addItemPassions}
          itemsCockpit={itemsMesses}
          saveEverything={saveEverything}
          screenPosY={screenPosY}
          title={strings.TITLE}
          textSelector={(x: any) => { return x.name }}
          textModal={strings.ADD_ITEM}
          textScreen={data[0]?.description}
        />
      </Cockpit>
    </>
  )
}
