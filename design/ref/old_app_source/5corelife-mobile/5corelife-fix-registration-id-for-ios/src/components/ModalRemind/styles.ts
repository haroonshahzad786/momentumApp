import { StyleSheet } from 'react-native'
import { vh, vw } from '../../helpers/dimensions';

export default StyleSheet.create({
    body: {
        width: '100%',
        height: '100%',
        backgroundColor: 'black',
        alignContent: 'center',
        justifyContent: 'center'
    },
    modalContainer: {
        flex: 1
    },
    container: {
        flex: 1,
        zIndex: 1,
    },
    containerAlien: {
        marginTop: vh(20),
        height: vw(140),
    },
    safeAreaViewContainer: {
        position: 'absolute',
        left: '50%',
        top: '65%',
        flex: 1,
    },
    animatedViewScreen: {
        // backgroundColor: 'yellow',
        alignSelf: 'center',
        position: 'absolute',
        flex: 1,
        bottom: -vh(150)
    },
    imageBackgroundScreen: {
        width: vw(95),
        height: vw(120)
    },
    viewTextScreen: {
        position: 'absolute',
        top: '4%',
        left: '5%',
        width: '90%',

    },
    viewTextScreenSecundary: {
        position: 'absolute',
        top: '17%',
        left: '4%',
        width: '90%',
    },
    viewTextScreenContent: {
        width: '90%',
        // backgroundColor: 'yellow',
    },
    containerContent: {
        marginTop: vh(26),
        marginLeft: vh(3),
        width: vw(80),
        height: vh(33),
        // backgroundColor: 'yellow',
    },
    textScreen: {
        // backgroundColor: 'yellow',
        textAlign: 'center',
        textAlignVertical: 'center',
        fontSize: vw(5.4),
        width: '100%'
    },
    descriptionScreen: {
        // backgroundColor: 'yellow',
        textAlign: 'center',
        textAlignVertical: 'center',
        fontSize: vw(4),
        width: '100%'
    },
    touchableOpacityButtonNext: {
        alignSelf: 'center',
        position: 'absolute',
        zIndex: 10,
        // right: -vw(45),
        // bottom: -vh(35),
        right: vw(1),
        bottom: -vh(6),
    },
    imageButtonNext: {
        width: vw(15)
    },
    okButton: {
        /* flex: 1,
         flexDirection: 'row',
         alignItems: 'center',
         justifyContent: 'flex-end',
         marginRight: vh(10)*/

        // flexDirection: 'row',
        // alignItems: 'flex-end',
        // justifyContent: 'space-around'
        padding: 0,
        margin: 0,
        position: 'absolute',
        bottom: '0%',
        left: '35%'
    },

    lineMachine: {
        color: 'black',
        fontSize: 20,
    },

    imageFormBack: {
        width: vw(80),
        height: 54,
        alignSelf: 'center',
        alignItems: 'center',
        justifyContent: 'center'
    },

    titleText: {
        fontFamily: "CanterBold",
        fontSize: vw(8),
        alignSelf: 'center',
        letterSpacing: 1.5
    },

});