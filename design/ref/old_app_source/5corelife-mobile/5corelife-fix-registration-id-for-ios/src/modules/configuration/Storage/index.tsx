import React, { useState } from 'react'
import { Image, ImageBackground, Text, View } from 'react-native'
import {
  TouchableOpacity,
  TouchableWithoutFeedback
} from 'react-native-gesture-handler'
import { useRecoilState, useRecoilValue } from 'recoil'
import HeaderSettings from '../../../components/HeaderSettings'
import HeaderDots from '../../../components/HeaderDots';
import ModalQuests from '../../../components/ModalQuests'
import { vh, vw } from '../../../helpers/dimensions'
import { localDataAtom, storageAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import { logger } from '../../../helpers/logger'


export default ({ navigation: { navigate, pop } }: props) => {
  const {
    value: { fonts, palette },
  } = useRecoilValue(storageAtom)
  const [isModalVisible, setModalVisible] = useState<boolean>(false)
  const [modalMode, setModalMode] = useState<'new' | 'failed' | 'completed'>(
    'new',
  )
  const openModal = () => {
    setModalVisible(true)
  }

  const nextModalMode = () => {
    setModalVisible(false)
    if (modalMode === 'new') setModalMode('failed')
    else if (modalMode === 'failed') setModalMode('completed')
    else setModalMode('new')
  }
  const [localData, setLocalData] = useRecoilState(localDataAtom)

  logger.debug("line 38 Storage.index localData: ", localData.value.currentCheckin)
  // TODO: Check th paameters in ModalQuest will be sent.
  // passed tmporaly questOrMission with a default value, but
  // we need to change later
  return (
    <>
      <ModalQuests
        daysNumberStyle={[
          fonts.QUEST_DAYS_NUMBER,
          { color: palette.TEXT_TERTIARY },
        ]}
        daysDescriptionStyle={[
          fonts.QUEST_DAYS_DESCRIPTION,
          { color: palette.TEXT_TERTIARY },
        ]}
        questDescriptionStyle={[
          fonts.QUEST_DESCRIPTION,
          { color: palette.TEXT_PRIMARY },
        ]}
        onClickOk={nextModalMode}
        touchableOpacityContainerButtonStyle={{
          width: vw(25),
          height: vh(7),
          borderRadius: vw(10),
          borderWidth: vw(0.5),
          borderColor: palette.BUTTON_BORDER,
          backgroundColor: palette.SUCCESS,
        }}
        textTitleButtonStyle={[
          styles.textDoneButton,
          fonts.BUTTON_MEDIUM,
          {
            color: palette.TEXT_PRIMARY,
            textShadowColor: palette.TEXT_PRIMARY_SHADOW,
          },
        ]}
        isVisible={isModalVisible}
        currentCheckIn={localData.value.currentCheckin}
        questOrMission='quest'
      />
      <ImageBackground
        style={styles.container}
        source={require('../../../assets/images/storage/background.png')}
        resizeMode={'cover'}>

        <View style={styles.containerSub}>

          <HeaderDots
            dotsCount={3}
            activeDotIndex={1}
            onBackButton={() => { navigate('Cores') }}
          />

          <HeaderSettings
            title={strings.TITLE}
            textTitleStyle={[
              fonts.CORE_TITLE,
              {
                color: palette.TEXT_PRIMARY,
                textShadowColor: palette.TEXT_PRIMARY_SHADOW,
              },
            ]}
            leftArrowNavigation={() => { navigate('Settings') }}
            rightArrowNavigation={() => { navigate('Profile') }}
          />

          <TouchableWithoutFeedback onPress={openModal}>
            <View
              style={[
                styles.containerCardQuest,
                {
                  backgroundColor: palette.SETTINGS_CARD_BACKGROUND,
                  borderColor: palette.SETTINGS_CARD_BORDER,
                },
              ]}>
              <View style={styles.containerCardQuestTextHeader}>
                <Text
                  style={[
                    styles.textQuestHeader,
                    fonts.SETTINGS_CARD_TITLE,
                    { color: palette.TEXT_PRIMARY },
                  ]}>
                  {strings.QUEST_HEADER}
                </Text>
              </View>

              <View style={styles.containerCardQuestImageLine}>
                <Image
                  style={styles.imageCardQuestLine}
                  source={require('../../../assets/images/storage/line.png')}
                  resizeMode={'contain'}
                />
              </View>

              <View style={styles.containerCardQuestTextTitle}>
                <Text
                  style={[
                    styles.textQuestHeader,
                    fonts.SETTINGS_CARD_QUEST,
                    { color: palette.TEXT_TERTIARY },
                  ]}>
                  {strings.QUEST_TITLE}
                </Text>
              </View>

              <View style={styles.containerCardQuestTextDescription}>
                <Text
                  style={[
                    styles.textQuestDescription,
                    fonts.SETTINGS_CARD_PARAGRAPH,
                    { color: palette.TEXT_PRIMARY },
                  ]}>
                  {strings.QUEST_DESCRIPTION}
                </Text>
              </View>
            </View>
          </TouchableWithoutFeedback>
          <View style={styles.containerImprovements}>
            <View style={styles.containerImageImprovementsText}>
              <Image
                style={styles.imageImprovementsText}
                source={require('../../../assets/images/storage/improvements.png')}
                resizeMode={'cover'}
              />
            </View>

            <TouchableOpacity
              style={styles.containerImageImprovementsIcon}
              onPress={() => {
                navigate('Improvements')
              }}>
              <Image
                style={styles.imageImprovementsIcon}
                source={require('../../../assets/images/storage/improvements_button.png')}
                resizeMode={'contain'}
              />
            </TouchableOpacity>
          </View>

          <View style={styles.containerTrophies}>
            <View style={styles.containerImageTrophiesText}>
              <Image
                style={styles.imageTrophiesText}
                source={require('../../../assets/images/storage/trophies.png')}
                resizeMode={'cover'}
              />
            </View>

            <TouchableOpacity
              style={styles.containerImageTrophiesIcon}
              onPress={() => {
                navigate('Trophies')
              }}>
              <Image
                style={styles.imageTrophiesIcon}
                source={require('../../../assets/images/storage/trophies_button.png')}
                resizeMode={'contain'}
              />
            </TouchableOpacity>
          </View>

          <View style={styles.containerBonus}>
            <View style={styles.containerImageBonusText}>
              <Image
                style={styles.imageBonusText}
                source={require('../../../assets/images/storage/bonus.png')}
                resizeMode={'cover'}
              />
            </View>

            <TouchableOpacity
              style={styles.containerImageBonusIcon}
              onPress={() => {
                navigate('Bonus')
              }}>
              <Image
                style={styles.imageBonusIcon}
                source={require('../../../assets/images/storage/bonus_button.png')}
                resizeMode={'contain'}
              />
            </TouchableOpacity>
          </View>
        </View>
      </ImageBackground>
    </>
  )
}
