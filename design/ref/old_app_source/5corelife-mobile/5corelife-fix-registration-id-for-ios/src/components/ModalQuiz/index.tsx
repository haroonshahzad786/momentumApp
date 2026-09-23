import React, { useRef } from 'react'

import props from './props'
import ModalQuizResult from './ModalQuizResult'
import ModalQuizStep from './ModalQuizStep'

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
  isVisible,
  core
}: props) => {
  const [step, setStep] = React.useState(0)
  const [value, setValue] = React.useState<any>(0)
  const [answer1, setAnswer1] = React.useState<any>(false)
  const [answer2, setAnswer2] = React.useState<any>(false)
  const [answer3, setAnswer3] = React.useState<any>(false)
  const [quiz, setQuiz] = React.useState<any>({
    quiz: true,
    quiz1: false,
    quiz2: false
  })
  const onClickInternal = () => {
    if (answer2 && !answer3) { setAnswer3(value); }
    if (answer1 && !answer2) { setAnswer2(value); setQuiz({ ...quiz, quiz1: false, quiz2: true }) }
    if (!answer1) { setAnswer1(value); setQuiz({ ...quiz, quiz: false, quiz1: true }) }
    setValue(0)
    if (step === 3) {
      setStep(0)
      setAnswer1(false)
      setAnswer2(false)
      setAnswer3(false)
      onClickOk()
    } else setStep(step + 1)
  }

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
    onClickOk: onClickInternal,
    setValue,
    answer1,
    answer2,
    answer3,
    quiz,
    value,
    isVisible,
    core,
  }

  if (step === 3) return <ModalQuizResult {...childProps} back={false} />
  return <ModalQuizStep key={step} {...childProps} />
}
