import React from 'react'
import props from './props'
import ModalQuizAllResult from './ModalQuizAllResult'
import ModalQuizAllCore from './ModalQuizStepAllCore'
import ModalQuizResult from '../ModalQuizResult'
import { logger } from '../../../helpers/logger'

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
  isVisible,
  setQuizModalVisible,
  completedQuiz,
  total,
  quiz,
  // isModalVisibled
}: props) => {

  const [isVisible_allCoresResult, setCoresResultModal] = React.useState<boolean>(false);
  const [isVisible_coreResultDetail, setCoreResultDetailModal] = React.useState<boolean>(false);
  const [isVisible_coreAnswer, setCoreAnswerModal] = React.useState<boolean>(isVisible);
  const [result, setResult] = React.useState<any[]>([])
  const onClick = (value: any) => {
    logger.debug('-> (USER ACTION) FINISHING QUIZ, SHOWING RESULTS');
    setResult(value);
    setCoreAnswerModal(false);
    setCoresResultModal(true);
  }

  const [answer, setAnswer] = React.useState<{ point: number, name: string }>({
    point: 0,
    name: ''
  })

  const clickWhat = (value: { point: number, name: string }) => {

    logger.debug('-> (USER ACTION) SHOW MODAL QUIZ RESULT DETAIL OF CORE: ' + value.name);
    setAnswer({
      point: value.point,
      name: value.name
    })
    setCoresResultModal(false)
    setCoreResultDetailModal(true)
  }

  const showCore = () => {
    logger.debug('-> (USER ACTION) SHOW MODAL QUIZ RESULT WITH ALL CORES');
    setCoreResultDetailModal(false)
    setCoresResultModal(true)
  }

  const onClickOk = async () => {
    logger.debug('-> (USER ACTION) CONFIRM RESULT OF QUIZ');
    setCoresResultModal(false);
    setQuizModalVisible(false);
    await completedQuiz();
  }

  const modalQuizAllCore = {
    quizTitleStyle,
    quizSubtitleStyle,
    quizQuestionsHeaderStyle,
    quizQuestionAnswerStyle,
    quizQuestionDescriptionStyle,
    quizScoreBigStyle,
    quizScoreSmallStyle,
    touchableOpacityContainerButtonStyle,
    textTitleButtonStyle,
    onClickOk: onClick,
    isVisible: isVisible_coreAnswer,
    quiz,
  }

  const modalQuizAllResult = {
    quizTitleStyle,
    quizSubtitleStyle,
    quizQuestionsHeaderStyle,
    touchableOpacityContainerButtonStyle,
    textTitleButtonStyle,
    isVisible: isVisible_allCoresResult,
    onClickOk,
    clickWhat,
    isVisible_allCoresResult,
    result,
    total,
  }

  const modalQuizResult = {
    quizTitleStyle,
    quizSubtitleStyle,
    quizQuestionsHeaderStyle,
    onClickOk: showCore,
    touchableOpacityContainerButtonStyle,
    textTitleButtonStyle,
    quizQuestionAnswerStyle,
    quizQuestionDescriptionStyle,
    quizScoreBigStyle,
    quizScoreSmallStyle,
    isVisible: isVisible_coreResultDetail,
    answer1: { point: answer.point },
    answer2: { point: 0 },
    answer3: { point: 0 },
  }

  return (
    <>
      {isVisible_coreAnswer && <ModalQuizAllCore {...modalQuizAllCore} />}
      {isVisible_allCoresResult && <ModalQuizAllResult {...modalQuizAllResult} />}
      {isVisible_coreResultDetail && <ModalQuizResult {...modalQuizResult} back={true} core={answer.name} />}
    </>
  )
}
