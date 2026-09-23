import React, { useEffect, useState } from 'react'
import {
  Animated,
  Easing
} from 'react-native'
import { useRecoilState, useRecoilValue } from 'recoil'
import Cockpit from '../../../components/Cockpit'
import CockpitListItems from '../../../components/CockpitListItems'
import { URL } from '../../../helpers/api'
import { fetchAxios } from '../../../helpers/axios'
import { vh } from '../../../helpers/dimensions'
import { setAtomAxios } from '../../../helpers/recoil'
import {
  inspirationsAtom,
  storageAtom,
  oneTimeAtom
} from '../../../recoil/atoms'
import { CockpitList, CockpitListRequest, OneTime } from '../../../typescript/main'
import props from './props'
import strings from './strings'
import styles from './styles'
import { logger } from '../../../helpers/logger'


export default ({ navigation: { goBack }, route: { params } }: props) => {
  const {
    value: { token }
  } = useRecoilValue(storageAtom)

  const inspirations = useRecoilValue(inspirationsAtom)
  const [oneTime, setOneTime] = useRecoilState<any>(oneTimeAtom)

  const [data, setData] = useState<any[]>([])
  const [oneTimeState, setOneTimeState] = useState<OneTime[] | null>(null)
  const [itemsOneTime, setItemsOneTime] = useState<OneTime | null>(null)
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
      setAtomAxios(setOneTime, {
        method: 'GET',
        url: URL + `cockpit-list/${data[0]?.id}/`
      })
    }
  }, [setOneTime, data])

  useEffect(() => {
    setOneTimeState(oneTime?.value?.items ? JSON.parse(oneTime?.value?.items) : [])
  }, [setOneTimeState, oneTime.value?.items])

  useEffect(() => {
    Animated.timing(screenPosY, {
      toValue: vh(21.5),
      easing: Easing.out(Easing.ease),
      duration: 1500,
      useNativeDriver: true
    }).start()
  }, [screenPosY])

  const updateTopPeopleState = (index: number, text: string) => {
    let newTopPeopleState: OneTime[] = JSON.parse(
      JSON.stringify(oneTimeState)
    )
    newTopPeopleState[index].name = text
    setOneTimeState(newTopPeopleState)
  }

  const currentId = () => {
    if (oneTimeState && oneTimeState?.length > 0) {
      let max = oneTimeState.reduce((stack: any, { id }: any) => Math.max(stack, id), -Number.POSITIVE_INFINITY)
      return max + 1;
    }
    return 0;
  }

  const addItemTopPeople = (text: string, core: string) => {
    setItemsOneTime({
      id: currentId(),
      name: text,
      user: 0,
      core_name: core
    })
  }

  const saveEverything = async () => {
    try {
      const items: CockpitListRequest = {
        name: strings.TITLE,
        items: JSON.stringify(oneTimeState)
      }
      await fetchAxios<CockpitListRequest, CockpitList>(
        'PUT',
        URL + `cockpit-list/${data[0]?.id}/`,
        token,
        items
      )
      goBack()
    } catch (error: any) {
      logger.error('Cockpit OneTime error: ', error.response);
    }
  }

  const handleAdd = (value: any) => {
    if (value != null) {
      setOneTimeState([
        ...oneTimeState!,
        value
      ]);
      setItemsOneTime(null);
    }
  }

  return (
    <>
      <Cockpit>
        <CockpitListItems
          data={oneTimeState}
          goBack={goBack}
          inspirations={inspirations}
          onAdd={handleAdd}
          addItemCockpit={addItemTopPeople}
          itemsCockpit={itemsOneTime}
          saveEverything={saveEverything}
          screenPosY={screenPosY}
          title={strings.TITLE}
          textSelector={(x: any) => { return x.name }}
          textModal={strings.ADD_ITEM}
          styleBack={styles.styleBack}
          params={params?.params?.core}
          textScreen={data[0]?.description}
        />
      </Cockpit>
    </>
  )
}
