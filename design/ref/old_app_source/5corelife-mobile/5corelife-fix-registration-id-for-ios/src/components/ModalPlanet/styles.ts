import { StyleSheet } from 'react-native'
import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
    container: {
        position: 'absolute',
        // bottom: vw(27.5),
        // left: vw(18),
        width: vw(17),
        height: vh(10),
    },
    childrenContainer: {
        marginLeft: vw(1),
        marginTop: vh(.39),
        width: vw(15),
        height: vh(8.5),
    },
    iconContainer: {
        marginLeft: vw(5.4),
        marginTop: vh(.4),
        width: vw(4.3),
        height: vh(3),
    },
    textPrimary: {
        marginTop: -vh(.5),
        textAlign: 'center',
        fontSize: 10,
    },
    textSecundary: {
        textAlign: 'center',
        fontSize: vw(1),
        paddingTop: vh(.2),
        textTransform: 'lowercase',
        width: '70%',
        lineHeight: 3.5,
        alignSelf: 'center',
    },
    textThird: {
        textAlign: 'center',
        fontSize: vw(3),
        letterSpacing: vw(.5)
    },
})