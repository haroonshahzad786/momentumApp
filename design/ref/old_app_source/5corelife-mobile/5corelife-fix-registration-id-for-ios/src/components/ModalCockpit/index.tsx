import React, { useRef } from 'react'

import props from './props'
import ModalHabitOverview from './ModalHabitOverview'

export default ({
  quizTitleStyle,
  quizSubtitleStyle,
  quizQuestionsHeaderStyle,
  quizQuestionAnswerStyle,
  quizQuestionDescriptionStyle,
  quizScoreBigStyle,
  quizScoreSmallStyle,
  touchableOpacityContainerButtonStyle,
  textTitleButtonStyle,
  onClickOk,
  onCancel,
  isVisible,
  habitInfo,
  setItems,
  dataModal,
  items,
  goals,
  itemsNew,
}: props) => {

  const habitDefault = {
    id: dataModal.id,
    name: '',
    category: '',
  }
  let habitHandle = typeof dataModal.id === 'number' ? habitDefault : habitInfo;

  const childProps = {
    quizTitleStyle,
    quizSubtitleStyle,
    quizQuestionsHeaderStyle,
    quizQuestionAnswerStyle,
    quizQuestionDescriptionStyle,
    quizScoreBigStyle,
    quizScoreSmallStyle,
    touchableOpacityContainerButtonStyle,
    textTitleButtonStyle,
    onClickOk,
    onCancel,
    isVisible,
    setItems,
    dataModal,
    items,
    habitInfo: habitHandle,
    goals,
    itemsNew,
  }

  return <ModalHabitOverview {...childProps} />
}
