import React, { useRef } from 'react'
import { Text, View, Image, TextInput, Switch, TouchableOpacity, Platform } from 'react-native'

import props from './props'
import styles from './styles'
import strings from './strings'
import ModalScreenBase from '../../ModalScreenBase'
import { useRecoilValue } from 'recoil'
import { storageAtom } from '../../../recoil/atoms'
import CheckboxButton from '../../CheckboxButton'

export default ({
  quizTitleStyle,
  quizSubtitleStyle,
  quizQuestionsHeaderStyle,
  touchableOpacityContainerButtonStyle,
  textTitleButtonStyle,
  textInputParagraphStyle,
  habitElement,
  onClickOk,
  onCancel,
  isVisible,
  isNewAdd,
  format,
  fromMorning,
}: props) => {
  const imageMonitor = require('../../../assets/images/quiz/monitor.png');
  const imageLine = require('../../../assets/images/quiz/line.png');


  const [readonlyValue, setReadonly] = React.useState<boolean>(true);

  const [switcherValue, setSwitcherValue] = React.useState<boolean>(habitElement.positive ?? false);
  const [descriptionValue, setDescription] = React.useState<string>(habitElement?.description ?? '');
  const [habitName, setHabitName] = React.useState<string>(habitElement?.name ?? '');
  const [formedValue, setFormedValue] = React.useState<boolean>(habitElement.formed ?? false);
  const [favValue, setFavValue] = React.useState<boolean>(habitElement.favorite ?? false);

  React.useEffect(() => {
    isNewAdd ? setReadonly(false) : setReadonly(true);
    setSwitcherValue(habitElement.positive ?? false);
    setDescription(habitElement?.description ?? '');
    setHabitName(habitElement?.name ?? '');
    setFormedValue(habitElement.formed ?? false);
    setFavValue(habitElement.favorite ?? false);
  }, [isVisible]);

  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)

  const onClickFunction = async () => {

    const editedHabit = {
      id: habitElement.id,
      name: habitName,
      positive: switcherValue ?? false,
      description: descriptionValue ?? habitName,
      core: habitElement.core,
      formed: formedValue ?? false,
      daysRow: habitElement.daysRow ?? '',
      favorite: favValue ?? false,
    }
    await onClickOk(editedHabit);
  }

  return (
    <ModalScreenBase
      touchableOpacityContainerButtonStyle={
        touchableOpacityContainerButtonStyle
      }
      textTitleButtonStyle={textTitleButtonStyle}
      imageMonitor={imageMonitor}
      textTitle={strings.BUTTON_NEXT}
      onClick={(habitName && habitName.length > 1) ? onClickFunction : () => { }}
      onCancel={onCancel}
      isVisible={isVisible}
      heightOffset={-2}
      hasVeil={false}>
      <View style={styles.topSection}>
        <View style={styles.titleSection}>
          <Text style={[quizTitleStyle, styles.quizTitle]}>{readonlyValue ? strings.TITLE : isNewAdd ? strings.TITLE_NEW : strings.TITLE_EDIT}</Text>
          {readonlyValue ?
            <TouchableOpacity onPress={() => { setReadonly(false) }}>
              <Image
                style={[styles.editIcon, styles.quizTitleEdit]}
                source={require('../../../assets/images/overview/butEdit_2.png')}
              />
            </TouchableOpacity> : null}
        </View>
        {!fromMorning &&
          <View style={[styles.editIconBox]} >
            <TouchableOpacity onPress={() => { setFavValue(!favValue) }} disabled={readonlyValue}>
              {favValue ? <Image
                style={[styles.favIcon]}
                source={require('../../../assets/images/shared/butFavOn.png')}
              /> : <Image
                style={[styles.favIcon]}
                source={require('../../../assets/images/shared/butFavOff.png')}
              />}
            </TouchableOpacity>
          </View>
        }
        {/* <Text style={[quizSubtitleStyle, styles.quizSubtitle]}>
          {habitElement.name}
        </Text> */}
        <View style={styles.questionRow}>
          <View style={styles.titleBox}>
            <TextInput
              style={[quizSubtitleStyle, styles.inputTitle]}
              value={habitName}
              editable={!readonlyValue}
              pointerEvents={Platform.OS === 'ios' ? 'auto' : 'none'}
              onChangeText={(text) => setHabitName(text)}
            />
          </View>
        </View>
        {!fromMorning &&
          <View style={styles.viewSwitch}>
            <Text
              style={[
                styles.textSwitch,
                fonts.SWITCH,
                { color: palette.TEXT_TERTIARY }
              ]}>
              {strings.SWITCHER_OP1}
            </Text>
            <Switch
              style={styles.sizeSwitcher}
              trackColor={{
                true: palette.TEXT_TERTIARY,
                false: palette.BUTTON_BORDER
              }}
              thumbColor={switcherValue ? palette.TEXT_SECONDARY : palette.TEXT_QUATERNARY}
              onValueChange={(value: boolean) => {
                setSwitcherValue(value);
              }}
              disabled={readonlyValue}
              value={switcherValue}
            />
            <Text
              style={[
                styles.textSwitch,
                fonts.SWITCH,
                { color: palette.TEXT_TERTIARY }
              ]}>
              {strings.SWITCHER_OP2}
            </Text>
          </View>
        }
      </View>
      <View style={styles.middleSection}>
        <Image
          style={styles.lineImage}
          source={imageLine}
          resizeMode={'stretch'}
        />

        <View style={styles.questionHeader}>
          <Text style={[quizQuestionsHeaderStyle, styles.quizQuestionsHeader]}>
            {strings.DESCRIPTION_BOX}
          </Text>
        </View>

        <View style={styles.descriptionBox}>
          <TextInput
            style={[textInputParagraphStyle, { textAlign: 'center', textAlignVertical: 'top' }]}
            value={descriptionValue}
            multiline
            editable={!readonlyValue}
            pointerEvents={Platform.OS === 'ios' ? 'auto' : 'none'}
            onChangeText={(text) => setDescription(text)}
          />
        </View>
      </View>
      {!format &&
        <View style={styles.bottomSection}>
          <CheckboxButton
            onPress={() => { setFormedValue(!formedValue) }}
            label={strings.FORMED_HABIT_CHECK}
            labelFontStyle={[fonts.CORE_HABIT_CHECK_LIST_HEADER, {
              color: palette.TEXT_PRIMARY,
              textShadowColor: palette.TEXT_PRIMARY_SHADOW
            }]}
            backgroundColor={palette.TEXT_TERTIARY}
            initialState={formedValue}
            disabled={readonlyValue}
          />
        </View>
      }
    </ModalScreenBase>
  )
}
