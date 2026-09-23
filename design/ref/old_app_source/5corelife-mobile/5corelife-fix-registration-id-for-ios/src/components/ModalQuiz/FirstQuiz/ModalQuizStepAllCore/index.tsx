import React from 'react'
import { Image, ScrollView, Text, TouchableOpacity, View } from 'react-native'
import { vh, vw } from '../../../../helpers/dimensions'
import { buildQuiz } from '../../../../helpers/listQuiz'
import ModalScreenBase from '../../../ModalScreenBase'
import { URL } from '../../../../helpers/api';
import { fetchAxios } from '../../../../helpers/axios';
import props from './props'
import strings from './strings'
import styles from './styles'
import { useRecoilValue } from 'recoil'
import { storageAtom } from '../../../../recoil/atoms'
import { logger } from '../../../../helpers/logger'

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
  quiz,
  core,
  isVisible,
}: props) => {
  const imageMonitor = require('../../../../assets/images/quiz/monitor.png')
  const imageLine = require('../../../../assets/images/quiz/line.png')
  const imageTickedQuestion = require('../../../../assets/images/quiz/iconCheckOff.png')
  const [selected, setSelected] = React.useState<string>("");
  const {
    value: { token }
  } = useRecoilValue(storageAtom)

  const [mindset, setMindset] = React.useState<any>()
  const [emosional, setEmosional] = React.useState<any>()
  const [relation, setRelation] = React.useState<any>()
  const [physical, setPhysical] = React.useState<any>()
  const [career, setCareer] = React.useState<any>()
  // const [cores, setCore] = React.useState<{ answer: string, point: number, id: number, core_name: string }>({ answer: '', point: 0, id: 0, core_name: '' });

  const handlePress = (key: any, data: any) => {
    key.core_name = data.core_name;
    switch (data.core_name) {
      case 'MINDSET':
        setMindset({ ...key, mindset })
        break;
      case 'EMOTIONAL_HEALTH':
        setEmosional({ ...key, emosional })
        break;
      case 'RELATIONSHIPS':
        setRelation({ ...key, relation })
        break;
      case 'PHYSICAL_HEALTH':
        setPhysical({ ...key, physical })
        break;
      case 'CAREER_FINANCES':
        setCareer({ ...key, career })
        break;
    }
    setSelected(key.id)
  };

  const handleCore = () => {
    return [
      {
        image: require('../../../../assets/images/overview/iconMindset.png'),
        point: mindset.point + mindset?.mindset?.point + mindset?.mindset?.mindset?.point,
        name: 'Mindset', // MINDSET
        title: 'MINDSET',
        color: '#AC2912',
      },
      {
        image: require('../../../../assets/images/overview/iconEmotional.png'),
        point: emosional.point + emosional?.emosional?.point + emosional?.emosional?.emosional?.point,
        name: 'Emotional Health / Giving Back', // 'EMOTIONAL HEALTH'
        title: 'EMOTIONAL_HEALTH',
        color: '#1B51A1',
      },
      {
        image: require('../../../../assets/images/overview/iconRelationships.png'),
        point: relation.point + relation?.relation?.point + relation?.relation?.relation?.point,
        name: 'Relationships', // 'RELATIONSHIPS'
        title: 'RELATIONSHIPS',
        color: '#C8348C',
      },
      {
        image: require('../../../../assets/images/overview/iconPhysical.png'),
        point: physical.point + physical?.physical?.point + physical?.physical?.physical?.point,
        name: 'Physical HealTH', // PHYSICAL HEALTH
        title: 'PHYSICAL_HEALTH',
        color: '#7D2C7D',
      },
      {
        image: require('../../../../assets/images/overview/iconPhysical_2.png'),
        point: career.point + career?.career?.point + career?.career?.career?.point,
        name: 'Career & Finances', // 'CAREER & FINANCES'
        title: 'CAREER_FINANCES',
        color: '#6E9A30',
      }
    ]
  }

  const postQuiz = async (data: any) => {
    await fetchAxios(
      'POST',
      URL + 'core-quiz/',
      token,
      data
    )
  }

  const [state, setState] = React.useState(0);
  const onPress = () => {
    // buildCore();
    logger.debug("line 118 ModalQuiz.FirstQuiz.ModalQuizStepAllCore.index emosional: ", emosional);
    if (state <= 18) { // 13
      setState(state + 1);
      setSelected("");
    }
    else {
      if (typeof emosional?.emosional?.emosional?.point === 'number') {
        postQuiz(buildQuiz(mindset, emosional, relation, physical, career))
        const coreResults = handleCore();
        onClickOk(coreResults);
      }
      else
      logger.debug('-> (USER ACTION) SAVING LAST ANSWER, TOUCH AGAIN TO CONTINUE.');
    }
  }

  const handleCurrent = () => {
    if (quiz[state].intro) onPress()
    else {
      if (selected) onPress()
      else () => { }
    }

  }

  return (
    <ModalScreenBase
      touchableOpacityContainerButtonStyle={
        touchableOpacityContainerButtonStyle
      }
      textTitleButtonStyle={textTitleButtonStyle}
      imageMonitor={imageMonitor}
      textTitle={state <= 18 ? strings.BUTTON_NEXT : quiz[state].intro ? strings.BUTTON_NEXT : strings.BUTTON_OK}
      onClick={handleCurrent}
      isVisible={isVisible}
      heightOffset={-2}
    >

      {quiz[state].intro
        ?
        <>
          <View style={styles.topSection}>
            <Text style={[quizTitleStyle, styles.quizTitle]}>QUIZ</Text>
            <Image source={quiz[state].image} style={styles.imageLogo} resizeMode={'cover'} />
            <Text style={[quizSubtitleStyle, styles.subHeader]}>
              {quiz[state].title}
            </Text>
            <View style={styles.containerDescription}>
              <Text style={[quizQuestionAnswerStyle, styles.textTitle]}>
                {quiz[state].description}
              </Text>
            </View>
          </View>
          <View style={styles.containerFooter}>
            <Text style={[quizTitleStyle, styles.footer]}>
              {strings.FOOTER}
            </Text>
          </View>
        </>
        :
        <>
          <View style={styles.topSection}>
            <Text style={[quizTitleStyle, styles.quizTitle]}>QUIZ</Text>
            <Text style={[quizSubtitleStyle, styles.quizSubtitle, { fontSize: String(quiz[state].question).length < 45 ? vw(10) : vw(7) }]}>
              {quiz[state].question}
            </Text>
          </View>
          <View style={styles.middleSection}>
            <Image
              style={styles.lineImage}
              source={imageLine}
              resizeMode={'stretch'}
            />
            <View style={styles.questionHeader}>
              <Text style={[quizQuestionsHeaderStyle, styles.quizQuestionsHeader]}>
                Select your answer
              </Text>
            </View>
            {quiz[state].answer.map((response: any, index: number) =>
              <View style={[styles.questionBlock]} key={response.answer.id}>
                <View style={styles.questionRow2} key={`answer${index}`}>
                  <TouchableOpacity style={[styles.questionTickContainer2]} onPress={() => handlePress(response, quiz[state])} key={response.id}>
                    <Image
                      style={styles.questionTick2}
                      source={imageTickedQuestion}
                      resizeMode={'contain'}
                    />
                    <Text style={[quizScoreSmallStyle, styles.questionTickCharacter2]}>
                      {selected === response.id && "✓"}
                    </Text>
                  </TouchableOpacity>
                  <Text style={[styles.questionTextContainer2, {
                    marginTop: response.answer.length > 69 ? -10 : vh(1.5),
                  }]}>
                    <Text style={[quizQuestionDescriptionStyle, styles.textAnswer, { fontSize: response.answer.length > 110 ? vw(5.5) : vw(6.2) }]}>
                      {response.answer}
                    </Text>
                  </Text>
                </View>
              </View>
            )}
            <View style={styles.bottomSection}>
              <Text style={styles.quizScoreTextContainer}>
                <Text style={[quizScoreBigStyle, { fontSize: vw(11) }]}>{quiz[state].id}</Text>
                <Text style={[quizScoreSmallStyle, { fontSize: vw(11) }]}> / 15</Text>
              </Text>
            </View>
          </View>
        </>
      }
    </ModalScreenBase>
  )
}
