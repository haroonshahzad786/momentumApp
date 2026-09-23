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
import { inspirationsAtom, dailyRoutineAtom, storageAtom } from '../../../recoil/atoms'
import { CockpitList, DailyRoutine } from '../../../typescript/main'
import props from './props'
import strings from './strings'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { goBack } }: props) => {

  const {
    value: { token }
  } = useRecoilValue(storageAtom)

  const inspirations = useRecoilValue(inspirationsAtom)
  const [items, setItems] = useRecoilState<any>(dailyRoutineAtom)

  const [daily, setDaily] = useState<any[]>([])
  const [itemsState, setItemsState] = useState<DailyRoutine[] | null>([])
  const [itemsDailyRoutine, setitemsDailyRoutine] = useState<DailyRoutine | null>(null)
  const [screenPosY] = useState(new Animated.Value(0))

  useEffect(() => {
    (async () => {
      try {
        const cockpitList: CockpitList[] = await fetchAxios<null, CockpitList[]>(
          'GET',
          URL + 'cockpit-list/',
          token,
          null
        )
        let filter = cockpitList.filter((response: CockpitList) => response.name === strings.TITLE)
        setDaily(filter)
      } catch (error: any) {
        logger.error("CockpitList error: ", error);
      }
    })()
  }, [])


  useEffect(() => {
    if (daily.length) {
      setAtomAxios(setItems, {
        method: 'GET',
        url: URL + `cockpit-list/${daily[0]?.id}/`
      })
    }
  }, [setItems, daily])

  useEffect(() => {
    setItemsState(items?.value?.items ? JSON.parse(items?.value?.items) : [])
  }, [setItemsState, items?.value?.items])

  useEffect(() => {
    Animated.timing(screenPosY, {
      toValue: vh(21.5),
      easing: Easing.out(Easing.ease),
      duration: 1500,
      useNativeDriver: true
    }).start()
  }, [screenPosY])

  const addItemPassions = (text: string) => {
    setitemsDailyRoutine({
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
    logger.debug('line 90 cockpit.DailyRoutine.index ', "'nitemState: ", itemsState, "\ndaily: ", daily[0]?.id);
    try {
      await fetchAxios(
        'PUT',
        URL + `cockpit-list/${daily[0]?.id}/`,
        token,
        {
          name: strings.TITLE,
          items: JSON.stringify(itemsState)
        }
      )
      goBack()
    } catch (error: any) {
      logger.debug('COCKPIT DAILYROUTINE error: ', error);
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
          // onUpdate={updateTopPeopleState}
          addItemCockpit={addItemPassions}
          itemsCockpit={itemsDailyRoutine}
          saveEverything={saveEverything}
          screenPosY={screenPosY}
          title={strings.TITLE}
          textSelector={(x: any, i?: boolean) => { if (typeof i === 'number' && itemsState) { logger.debug('itemsState[i].name: ' + itemsState[i].name); return itemsState[i].name } else { return x.name } }}
          textModal={strings.ADD_ITEM}
          textScreen={daily[0]?.description}
        />
      </Cockpit>
    </>
  )
}
