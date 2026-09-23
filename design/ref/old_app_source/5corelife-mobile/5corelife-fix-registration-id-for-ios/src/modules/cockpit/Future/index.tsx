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
  futureAtom
} from '../../../recoil/atoms'
import { CockpitList, CockpitListRequest, Future } from '../../../typescript/main'
import props from './props'
import strings from './strings'
import styles from './styles'
import { logger } from '../../../helpers/logger'


export default ({ navigation: { goBack }, route: { params }, tutorial, navigateToNextStep, goNextStep, nextStep }: props) => {
  logger.info("[<Future>]")
  const {
    value: { token }
  } = useRecoilValue(storageAtom)

  const inspirations = useRecoilValue(inspirationsAtom)
  const [future, setFuture] = useRecoilState<any>(futureAtom)

  const [data, setData] = useState<any[]>([])
  const [futureState, setFutureState] = useState<Future[] | null>(null)
  const [itemsTopPerson, setItemsTopPerson] = useState<Future | null>(null)
  const [screenPosY] = useState(new Animated.Value(0))

  useEffect(() => {
    (async () => {
      try {
        const cockpitLists: CockpitList[] = await fetchAxios<null, CockpitList[]>(
          'GET',
          URL + 'cockpit-list/',
          token,
          null
        )
        logger.debug("line 46 cockpit.Future.index cokcpitLlists: ",cockpitLists)
        let filter = cockpitLists.filter((response: any) => response?.name === strings?.TITLE)
        logger.debug("line 48 cockpit.Future.index filter: ", filter)
        setData(filter)
      } catch (error: any) {
        logger.error("line 51 cockpit.Future.index error: ",error?.response)
      }
    })()
  }, [])

  useEffect(() => {
    if (data.length) {
      setAtomAxios(setFuture, {
        method: 'GET',
        url: URL + `cockpit-list/${data[0]?.id}/`
      })
    }
  }, [setFuture, data])

  useEffect(() => {
    setFutureState(future?.value?.items ? JSON.parse(future?.value?.items) : [])
  }, [setFutureState, future?.value?.items])

  useEffect(() => {
    Animated.timing(screenPosY, {
      toValue: vh(21.5),
      easing: Easing.out(Easing.ease),
      duration: 1500,
      useNativeDriver: true
    }).start()
  }, [screenPosY])

  const currentId = () => {
    if (futureState && futureState?.length > 0) {
      let max = futureState.reduce((stack: any, { id }: any) => Math.max(stack, id), -Number.POSITIVE_INFINITY)
      return max + 1;
    }
    return 0;
  }

  const addItemTopPeople = (text: string, core: string) => {
    setItemsTopPerson({
      id: currentId(),
      name: text,
      user: 0,
      core_name: core
    })
  }

  const saveEverything = async () => {
    logger.debug('line 96 cockpit.Future.index saveEverything data: ', data,"\nstrings.TITLE: ",strings.TITLE,"\nfutureState: ", futureState);
    try {
      const items: CockpitListRequest = {
        name: strings.TITLE,
        items: JSON.stringify(futureState)
      }
      await fetchAxios<CockpitListRequest, CockpitList>(
        'PUT',
        URL + `cockpit-list/${data[0]?.id}/`,
        token,
        items
      )
      goBack()
    } catch (error: any) {
      logger.error("line 113 cockpit.Future.index error: ",error.response);
    }
  }

  const handleAdd = (value: any) => {
    if (tutorial) goNextStep()
    if (value != null) {
      setFutureState([
        ...futureState!,
        value
      ]);
      setItemsTopPerson(null);
    }
  }

  return (
    <>
      <Cockpit>
        <CockpitListItems
          data={futureState}
          goBack={goBack}
          inspirations={inspirations}
          onAdd={handleAdd}
          // onUpdate={updateFearsState}
          addItemCockpit={addItemTopPeople}
          itemsCockpit={itemsTopPerson}
          saveEverything={saveEverything}
          screenPosY={screenPosY}
          title={strings.TITLE}
          textSelector={(x: any) => { return x.name }}
          textModal={strings.ADD_ITEM}
          styleBack={styles.styleBack}
          params={params?.params?.core}
          textScreen={data[0]?.description}
          tutorial={tutorial}
          navigateToNextStep={navigateToNextStep}
          nextStep={nextStep}
        />
      </Cockpit>
    </>
  )
}
