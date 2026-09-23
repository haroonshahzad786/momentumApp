import React, { useRef } from 'react'
import { Text, View, Image, TextInput, Switch, TouchableOpacity } from 'react-native'

import props from './props'
import styles from './styles'
import strings from './strings'
import ModalScreenBase from '../../ModalScreenBase'
import { useRecoilValue } from 'recoil'
import { storageAtom } from '../../../recoil/atoms'
import CheckboxButton from '../../CheckboxButton'
import DropDownPicker from 'react-native-dropdown-picker'
import { vw } from '../../../helpers/dimensions'
import { logger } from '../../../helpers/logger'

export default ({
  quizTitleStyle,
  quizSubtitleStyle,
  quizQuestionsHeaderStyle,
  touchableOpacityContainerButtonStyle,
  textTitleButtonStyle,
  onClickOk,
  onCancel,
  isVisible,
  setItems,
  dataModal,
  items,
  habitInfo,
  goals,
  itemsNew,
}: props) => {
  const imageMonitor = require('../../../assets/images/quiz/monitor.png');
  const imageLine = require('../../../assets/images/quiz/line.png');


  const [readonlyValue, setReadonly] = React.useState<boolean>(true);
  const [open, setOpen] = React.useState(false);
  const [value, setValue] = React.useState<any>('');
  const [cockpitName, setCockpitName] = React.useState<string>('');

  const onClickFunction = async () => {
    setValue('')
    setCockpitName('')
    const editedHabit: { id: number, name: string, category: string, length?: number, score?: number, new?: boolean } = {
      id: habitInfo.id,
      name: cockpitName,
      category: value,
    }
    if (goals) {
      editedHabit.score = 0
      value === 'Long-term (2500)' ? editedHabit.length = 2500 : editedHabit.length = 500
    }
    if (itemsNew) editedHabit.new = true
    await onClickOk(editedHabit);
  }

  React.useEffect(() => {
    setCockpitName(dataModal.title)
    setValue(dataModal.category)
    logger.debug("line 58 ModalCockpit.ModalHabitOverview.index dataModal: ", dataModal);
  }, [dataModal])

  return (
    <ModalScreenBase
      touchableOpacityContainerButtonStyle={
        touchableOpacityContainerButtonStyle
      }
      textTitleButtonStyle={textTitleButtonStyle}
      imageMonitor={imageMonitor}
      textTitle={strings.BUTTON_NEXT}
      onClick={(value.length && cockpitName.length > 1) ? onClickFunction : () => { }}
      onCancel={onCancel}
      isVisible={isVisible}
      heightOffset={-2}
      hasVeil={false}>
      <View style={styles.topSection}>
        <View style={styles.titleSection}>
          <Text style={[quizTitleStyle, styles.quizTitle]}>{strings.TITLE_COCKPIT}</Text>
          {readonlyValue ?
            <TouchableOpacity onPress={() => { setReadonly(false) }}>
              <Image
                style={[styles.editIcon, styles.quizTitleEdit]}
                source={require('../../../assets/images/overview/butEdit_2.png')}
              />
            </TouchableOpacity> : null}
        </View>
        <View style={styles.questionRow}>
          <View style={styles.titleBox}>
            <TextInput
              style={[quizSubtitleStyle, styles.inputTitle,]}
              value={cockpitName}
              autoFocus
              pointerEvents={'none'}
              placeholder="New Item"
              onChangeText={(text) => setCockpitName(text)}
            />
          </View>
        </View>
      </View>
      <View style={styles.middleSection}>
        <Image
          style={styles.lineImage}
          source={imageLine}
          resizeMode={'stretch'}
        />

        <View style={styles.questionHeader}>
          <Text style={[quizQuestionsHeaderStyle, styles.quizQuestionsHeader]}>
            {strings.CATEGORY}
          </Text>
        </View>

        <DropDownPicker
          style={{ backgroundColor: 'rgba(156, 155, 155, 0.26)' }}
          open={open}
          value={value}
          items={items}
          setOpen={setOpen}
          setValue={setValue}
          setItems={setItems}
          containerStyle={styles.dropDownPicker}
          mode={'SIMPLE'}
          placeholder="ITEMS"
          placeholderStyle={{
            "fontFamily": "A-SpaceLightDemo",
            "fontSize": vw(3),
            "letterSpacing": 0
          }}
          theme="DARK"
        />
      </View>
    </ModalScreenBase>
  )
}
