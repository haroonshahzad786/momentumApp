import React, { useEffect, useState } from 'react'
import {
  Animated, Easing
} from 'react-native'
import { useRecoilState, useRecoilValue } from 'recoil'
import Cockpit from '../../../components/Cockpit'
import CockpitListItemSelect from '../../../components/CockpitListItemSelect'
import { URL } from '../../../helpers/api'
import { fetchAxios, fetchAxiosMultiple } from '../../../helpers/axios'
import { vh } from '../../../helpers/dimensions'
import { setAtomAxios } from '../../../helpers/recoil'
import { goalsAtom, inspirationsAtom, storageAtom } from '../../../recoil/atoms'
import { Goals } from '../../../typescript/main'
import props from './props'
import strings from './strings'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { goBack } }: props) => {

  const {
    value: { token }
  } = useRecoilValue(storageAtom)

  const inspirations = useRecoilValue(inspirationsAtom)
  const [items, setItems] = useRecoilState<any>(goalsAtom)

  const [data, setData] = useState<any[]>([])
  const [itemsState, setItemsState] = useState<Goals[] | null>([])
  const [itemsStregths, setItemsStregths] = useState<Goals | null>(null)
  const [screenPosY] = useState(new Animated.Value(0))

  const getAllItems = () => {
    setAtomAxios(setItems, {
      method: 'GET',
      url: URL + `goals/`
    })
  }

  useEffect(() => {
    getAllItems()
  }, [setItems])

  useEffect(() => {
    setItemsState(items?.value ? items?.value : [])
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
    let newFearsState: Goals[] = JSON.parse(JSON.stringify(itemsState))
    newFearsState[index].name = text
    setItemsState(newFearsState)
  }

  const addItemStregths = (text: string) => {
    setItemsStregths({
      id: 0,
      name: text,
      length: 0,
      score: 0,
      completed: false
    })
  }

  const saveEverything = async () => {
    try {
      // TODO: Check how works Goals and fears
      fetchAxiosMultiple(itemsState!.map((fearState: any) => {
        if (fearState.new) {
          if (fearState.name.trim() !== '') {
            return {
              method: 'POST',
              url: URL + 'goals/',
              token,
              data: {
                name: fearState.name.trim(),
                length: fearState.id
              }
            }
          }
        } else {
          const fear = items.value?.find((fearItem: any) => fearItem.id === fearState.id)

          if (fear?.fear !== fearState.fear) {
            return {
              method: 'PATCH',
              url: URL + `fears/${fearState.id}`,
              token,
              data: {
                fear: fearState.fear.trim()
              }
            }
          }
        }
      })
      )
      goBack()
    } catch (error: any) {
      logger.error('Cockpit Goals error: ', error.response);
    }
  }

  const handleAdd = (value: any) => {
    setItemsState([
      ...itemsState!,
      value,
    ])
  }

  const deleteItemGoals = async (id: number, setModalVisibleDelete: Function) => {
    try {
      await fetchAxios(
        'DELETE',
        `${URL}goals/${id}/`,
        token,
        null
      )
      setModalVisibleDelete({ visibled: false, id: null })
      getAllItems()
    } catch (err: any) {
      logger.error("Goals.index Delete goals error:", err.response);
    }
  }

  const options = ['Short-term (500)', 'Long-term (2500)',]

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
          deleteItemGoals={deleteItemGoals}
          screenPosY={screenPosY}
          title={strings.name}
          textSelector={(x: any) => { return x.name }}
          textModal={strings.ADD_ITEM}
          textScreen={strings.description}
          goals={true}
          items={options}
        />
      </Cockpit>
    </>
  )
}
