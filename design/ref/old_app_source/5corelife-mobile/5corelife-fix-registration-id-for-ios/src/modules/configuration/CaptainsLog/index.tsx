import React, { useEffect, useState } from 'react'
import {
  ImageBackground,
  TouchableOpacity, View
} from 'react-native'
import { ScrollView } from 'react-native-gesture-handler'
import { useRecoilValue } from 'recoil'
import Accordion from '../../../components/Accordion'
import ButtonBack from '../../../components/ButtonBack'
import HeaderSettings from '../../../components/HeaderSettings'
import { URL } from '../../../helpers/api'
import { fetchAxios } from '../../../helpers/axios'
import { storageAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import { SelfReview } from '../../../typescript/main'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, goBack } }: props) => {
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom)

  const questions = [strings.QUESTION_0, strings.QUESTION_1, strings.QUESTION_2,]
  const [captainsLog, setCaptainsLog] = useState<SelfReview[]>([]);

  useEffect(() => {
    const fetchData = async () => {

      try {
        const selfReview: SelfReview[] = await fetchAxios<null, SelfReview[]>(
          'GET',
          URL + 'self-review',
          token,
          null
        )
        setCaptainsLog(selfReview)
      }
      catch (error) {
        logger.error("CaptainsLog error: ", JSON.stringify(error))
        setCaptainsLog([])
      }
    }

    fetchData();

  }, [])

  return (
    <>
      <ImageBackground
        style={styles.container}
        source={require('../../../assets/images/settings/background.png')}
        resizeMode={'cover'}>
        <View style={styles.containerSub}>
          <View style={styles.containerButtonBack}>
            <ButtonBack onPress={goBack} />
          </View>
          <TouchableOpacity
            style={styles.containerHeaderSettings}
            onPress={() => {
              navigate('CaptainsLog')
            }}>
            <HeaderSettings
              title={strings.TITLE}
              textTitleStyle={[
                fonts.CORE_TITLE,
                {
                  color: palette.TEXT_PRIMARY,
                  textShadowColor: palette.TEXT_PRIMARY_SHADOW
                }
              ]}
            />
          </TouchableOpacity>
          <ScrollView>
            <Accordion questions={questions} data={captainsLog} />
          </ScrollView>
        </View>
      </ImageBackground>
    </>
  )
}
