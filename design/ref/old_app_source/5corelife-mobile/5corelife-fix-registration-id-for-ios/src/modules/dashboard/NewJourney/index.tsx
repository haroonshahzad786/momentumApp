import React, { useState } from 'react'
import { View } from 'react-native'
import { useRecoilValue } from 'recoil'
import ModalJourney from '../../../components/ModalJourney'
import { vh, vw } from '../../../helpers/dimensions'
import { storageAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import { URL } from '../../../helpers/api'
import { fetchAxios } from '../../../helpers/axios'
import { UserRetrieve } from '../../../typescript/main'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, goBack } }: props) => {
  const {
    value: { fonts, palette, token },
  } = useRecoilValue(storageAtom)
  const [userProfileData, setUserProfileData] = useState<UserRetrieve>();

  React.useEffect(() => {
    logger.info('<MOUNT> |SCREEN| - New Journey');
    const fetchData = async () => {
      try {
        logger.debug("-> REFRESHING DATA OF CORES - Refersh data from core power y momentum.");
        logger.info('<FETCHING> - [USER_RETRIEVE]');
        const dataUserProfileResult: UserRetrieve = await fetchAxios<null, UserRetrieve>(
          'GET',
          URL + 'users/retrieve/',
          token,
          null
        );
        setUserProfileData(dataUserProfileResult);
      } catch (error) {

        logger.error('**ERROR** [GET-CORES_BY_USER] || [GET-USER_RETRIEVE]');
        logger.error('[ERROR INFO]: ' + JSON.stringify(error));
      }
    }

    fetchData();
  });

  return (
    <View style={{ backgroundColor: '#030303', height: '100%' }}>
      <ModalJourney
        onClickOk={() => goBack()}
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
        textMainHeader={strings.MAIN_HEADER}
        textContentHeader={strings.CONTENT_HEADER}
        textContentInfo={strings.CONTENT_INFO}
        isVisible={true}
      />
    </View>
  )
}
