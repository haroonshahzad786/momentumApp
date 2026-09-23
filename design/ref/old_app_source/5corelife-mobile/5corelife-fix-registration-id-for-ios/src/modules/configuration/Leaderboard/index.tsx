import React, { useEffect, useState } from 'react'
import { Image, ImageBackground, ImageComponent, Text, View } from 'react-native'
import { ScrollView, TouchableOpacity } from 'react-native-gesture-handler'
import { useRecoilValue } from 'recoil'
import { storageAtom } from '../../../recoil/atoms'
import { fetchAxiosNoCache } from '../../../helpers/axios'
import { URL } from '../../../helpers/api'
import ButtonBack from '../../../components/ButtonBack'
import HeaderSettings from '../../../components/HeaderSettings'
import props from './props'
import strings from './strings'
import styles from './styles'
import ButtonNext from '../../../components/ButtonNext'
import HeaderDots from '../../../components/HeaderDots'
import { getImprovementsColors } from '../../../helpers/internalDataManagement'
import Rocket from '../../../components/Rocket'
import { Leaderboards } from '../../../typescript/main'


export default ({ navigation: { navigate, pop, goBack } }: props) => {
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom)

  const [leaderBoard, setLeaderBoard] = useState<Leaderboards[]>([])
  useEffect(() => {
    (async () => {
      const leaderBoards: Leaderboards[] = await fetchAxiosNoCache<null, Leaderboards[]>(
        'GET',
        URL + 'users/leaderboard/',
        token,
        null
      )
      const orderApi = leaderBoards.sort((a: any, b: any) => {
        if (a.score > b.score) return -1;
        if (a.score < b.score) return 1;
        return 0
      });
      setLeaderBoard(orderApi);
    })()
  }, [])

  return (
    <>
      <ImageBackground
        style={[styles.container]}
        source={require('../../../assets/images/shared/background.png')}
        resizeMode={'cover'}>
        <View style={[styles.containerSub]}>
          <HeaderDots
            dotsCount={2}
            activeDotIndex={1}
            onBackButton={() => { navigate('Profile') }}
          />
          <HeaderSettings
            title={strings.TITLE}
            textTitleStyle={[
              fonts.CORE_TITLE,
              {
                color: palette.TEXT_PRIMARY,
                textShadowColor: palette.TEXT_PRIMARY_SHADOW
              }
            ]}
            rightArrowNavigation={() => { navigate('Overview') }}
          />
          <View style={[
            styles.containerBackCard
          ]}>
            <View
              style={[
                styles.containerCardQuest,
                {
                  backgroundColor: palette.SETTINGS_CARD_BACKGROUND,
                  borderColor: palette.SETTINGS_CARD_BORDER
                }
              ]}>
              <View style={[styles.containerCardQuestTextHeader, {
                borderBottomColor: palette.LEADERBOARD_HEADER_GRAY
              }]}>
                <Text
                  style={[
                    styles.textQuestHeader,
                    fonts.LIST_HEADER,
                    { color: palette.LEADERBOARD_HEADER_GRAY }
                  ]}>
                  {strings.HEADER_USER_COLUMN}
                </Text>
                <Text
                  style={[
                    styles.textQuestHeader,
                    styles.userListHeader,
                    fonts.LIST_HEADER,
                    { color: palette.LEADERBOARD_HEADER_GRAY }
                  ]}>
                  {strings.HEADER_SCORE_COLUMN}
                </Text>
              </View>
              <View style={[styles.containerRows]}>
                <ScrollView>
                  {leaderBoard.length ? leaderBoard.map((item: any, index: number) => (
                    <React.Fragment key={index}>
                      <View style={styles.containerScoreRow}>
                        <ImageBackground
                          style={[styles.imageImprovementsIcon]}
                          source={require('../../../assets/images/leaderboard/avatarCont.png')}
                          resizeMode={'cover'}
                        >
                          <Rocket
                            externalStyle={styles.rocketIcon}
                            wings={''}
                            turbines={''}
                            skinColor={item.armor}
                          />
                        </ImageBackground>
                        <Text
                          style={[
                            styles.textQuestDescription,
                            styles.rowText,
                            fonts.HABITS_ACCORDION,
                            { color: palette.TEXT_PRIMARY }
                          ]}>
                          {index + 1}.   {item.username}
                        </Text>
                        <Text
                          style={[
                            styles.textQuestDescription,
                            fonts.HABITS_ACCORDION,
                            {
                              color: palette.TEXT_PRIMARY,
                            }
                          ]}>
                          {item.score}
                        </Text>
                      </View>
                    </React.Fragment>)) : null
                  }
                </ScrollView>
              </View>
            </View>
          </View>
        </View>
      </ImageBackground>
    </>
  )
}
