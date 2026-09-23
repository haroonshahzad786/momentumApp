import React, { useEffect, useState } from 'react'
import {
  Animated,
  View,
  Easing
} from 'react-native'
import { useRecoilValue, useRecoilState } from 'recoil'
import Settings from '../../configuration/Settings'
import { vh } from '../../../helpers/dimensions'
import { storageAtom, userRetrieveAtom, localDataAtom } from '../../../recoil/atoms'
import AdviseMessage from '../AdviseMessage'
import props from './props'
import strings from './strings'
import styles from './styles'
import { fetchAxios } from '../../../helpers/axios'
import { URL } from '../../../helpers/api'
import ButtonNextStep from '../ButtonNextStep'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, goBack, reset } }: props) => {
  logger.info("[<StepEleven>]")
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom)
  const [storage, setStorage] = useRecoilState(storageAtom)
  const [userRetrieve, setUserRetrieve] = useRecoilState(userRetrieveAtom)
  const [localData, setLocalData] = useRecoilState(localDataAtom)
  const [screenPosY] = useState(new Animated.Value(0))
  useEffect(() => {
    Animated.timing(screenPosY, {
      delay: 500,
      toValue: vh(82.5),
      easing: Easing.out(Easing.ease),
      duration: 2000,
      useNativeDriver: true
    }).start()
  }, [screenPosY])

  const [statusTutorialPicker, setStatusTutorialPicker] = useState({
    morning: false,
    night: false
  })
  const [disabled, setDisabled] = useState(false)
  const theEndTutorial = async () => {
    try {
      await fetchAxios(
        'PATCH',
        URL + 'users/retrieve/',
        token,
        {
          email: userRetrieve.value?.email,
          username: userRetrieve.value?.username,
          user_profile: {
            onboarding: true
          },
        },
      )
      setStorage({
        ...storage,
        value: {
          ...storage.value,
          onboarding: true
        },
      })
      setLocalData({
        ...localData,
        value: {
          ...localData.value,
          onboarding: true
        }
      })
      return () => {
        setStorage({
          ...storage,
          value: {
            ...storage.value,
            onboarding: true
          },
        })
      }
    } catch (error: any) {
      logger.error('**ERROR** [PUT-RETRIEVE]');
      logger.error('line 104 StepEleven.index [ERROR INFO]: ' + JSON.stringify(error.response));
    }
  }

  return (
    <>
      <View style={[styles.safeAreaViewContainer]}>
        <AdviseMessage
          subtitle={strings.textTabs[statusTutorialPicker.morning && statusTutorialPicker.night ? 1 : 0].info}
          slideScreens={2}
          slideActive={statusTutorialPicker.morning && statusTutorialPicker.night ? 2 : 1}
          toTop={true}
          disabled={disabled}
          reverse={true}
        />

        {
          (statusTutorialPicker.morning && statusTutorialPicker.night) &&
          <ButtonNextStep
            onPress={() => theEndTutorial()}
            stylePosition={styles.buttonNextStepPosition}
          />
        }
      </View>
      <View style={[styles.pageContainer, statusTutorialPicker.morning && statusTutorialPicker.night ? styles.positionAbsolute : null]}>
        <Settings
          navigation={{ navigate, goBack, reset }}
          setDisabled={setDisabled}
          onBoardingMode={true}
          setendTutorial={setStatusTutorialPicker}
          setendStatusTutorial={statusTutorialPicker}
        />
      </View>
    </>
  )
}
