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
  textInputParagraphStyle,
  habitInfo,
  isNewAdd,
  format,
  fromMorning
}: props) => {
  const habitDefault = {
    name: '',
    positive: true,
    description: '',
    core: 'MINDSET',
    formed: true,
    daysRow: '',
    favorite: false,
  }

  const habitElement = habitInfo ?? habitDefault;

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
    textInputParagraphStyle,
    habitElement,
    isNewAdd: isNewAdd ?? false,
    format,
    fromMorning,
  }

  return <ModalHabitOverview {...childProps} />
}
