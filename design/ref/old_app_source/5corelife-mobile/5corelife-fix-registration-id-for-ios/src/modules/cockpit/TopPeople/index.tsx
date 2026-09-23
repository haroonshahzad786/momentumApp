import React, { useEffect, useState } from 'react'
import {
  Animated,
  Easing
} from 'react-native'
import { useRecoilState, useRecoilValue } from 'recoil'
import Cockpit from '../../../components/Cockpit'
import CockpitListItems from '../../../components/CockpitListItems'
import CockpitListItemsOrder from '../../../components/CockpitListItemsOrder'
import { URL } from '../../../helpers/api'
import { fetchAxios, fetchAxiosMultiple } from '../../../helpers/axios'
import { vh } from '../../../helpers/dimensions'
import { setAtomAxios } from '../../../helpers/recoil'
import {
  inspirationsAtom,
  storageAtom,
  topPeopleAtom
} from '../../../recoil/atoms'
import { CockpitList, CockpitListRequest, TopPerson } from '../../../typescript/main'
import props from './props'
import strings from './strings'
import styles from './styles'
import { logger } from '../../../helpers/logger'


export default ({ navigation: { goBack }, route: { params } }: props) => {
  const {
    value: { token }
  } = useRecoilValue(storageAtom)

  const inspirations = useRecoilValue(inspirationsAtom)
  const [topPeople, setTopPeople] = useRecoilState<any>(topPeopleAtom)

  const [data, setData] = useState<any[]>([])
  const [topPeopleState, setTopPeopleState] = useState<TopPerson[] | any>(null)
  const [itemsTopPerson, setItemsTopPerson] = useState<TopPerson | null>(null)
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
      setAtomAxios(setTopPeople, {
        method: 'GET',
        url: URL + `cockpit-list/${data[0]?.id}/`
      })
    }
  }, [setTopPeople, data])

  useEffect(() => {
    setTopPeopleState(topPeople?.value?.items ? JSON.parse(topPeople?.value?.items) : [])
  }, [setTopPeopleState, topPeople.value])

  useEffect(() => {
    Animated.timing(screenPosY, {
      toValue: vh(21.5),
      easing: Easing.out(Easing.ease),
      duration: 1500,
      useNativeDriver: true
    }).start()
  }, [screenPosY])

  const updateTopPeopleState = (index: number, text: string) => {
    let newTopPeopleState: TopPerson[] = JSON.parse(
      JSON.stringify(topPeopleState)
    )
    newTopPeopleState[index].name = text
    setTopPeopleState(newTopPeopleState)
  }

  const addItemTopPeople = (text: string, core: string) => {
    setItemsTopPerson({
      id: currentId(),
      name: text,
      user: 0,
      core_name: core
    })
  }

  const currentId = () => {
    if (topPeopleState && topPeopleState?.length > 0) {
      let max = topPeopleState.reduce((stack: any, { id }: any) => Math.max(stack, id), -Number.POSITIVE_INFINITY)
      return max + 1;
    }
    return 0;
  }

  const saveEverything = async () => {
    try {
      const items: CockpitListRequest = {
        name: strings.TITLE,
        items: JSON.stringify(topPeopleState)
      }
      await fetchAxios<CockpitListRequest, CockpitList>(
        'PUT',
        URL + `cockpit-list/${data[0]?.id}/`,
        token,
        items
      )
      goBack()
    } catch (error: any) {
      logger.debug('Cockpit ToPeople error: ', error.response)
    }
  }

  const handleAdd = (value: any) => {
    logger.debug("line 117 cockpit.TopPeople.index value: ", value, " topPeopleState: ", topPeopleState);
    if (value != null) {
      setTopPeopleState([
        ...topPeopleState!,
        value
      ]);
      setItemsTopPerson(null);
    }
  }

  return (
    <>
      <Cockpit>
        <CockpitListItems
          data={topPeopleState}
          goBack={goBack}
          inspirations={inspirations}
          onAdd={handleAdd}
          styleBack={styles.styleBack}
          addItemCockpit={addItemTopPeople}
          itemsCockpit={itemsTopPerson}
          saveEverything={saveEverything}
          screenPosY={screenPosY}
          title={strings.TITLE}
          textSelector={(x: any) => { return x.name }}
          textModal={strings.ADD_ITEM}
          params={params?.params?.core}
          textScreen={data[0]?.description}
        />
      </Cockpit>
    </>
  )
}
