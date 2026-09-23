import { StyleSheet } from 'react-native'
import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column'
  },
  headerText: {
    marginTop: vh(5),
    fontFamily: "A-SpaceDemo",
    fontSize: vw(4.5),
    alignSelf: 'center',
  },
  earthContainer: {
  },
  titleContainer: {
  },
  titleText: {
    fontFamily: "CanterBold",
    fontSize: vw(10),
    alignSelf: 'center',
  },
  headerSection: {
    flexBasis: '15%',
    alignItems: 'center',
    //backgroundColor: 'yellow'
  },
  earthSection: {
    flexBasis: '40%',
    alignItems: 'center',
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'space-around',
    //backgroundColor: 'red'
  },
  contentSection: {
    flexBasis: '45%',
    alignItems: 'center',
    //backgroundColor: 'blue'
  },
  earthImage: {
    height: vh(25),
    width: vh(25),
  },
  imageFormBack: {
    width: vw(70),
    height: vh(11),
    alignSelf: 'center',
    alignItems: 'center',
    justifyContent: 'center'
  },
  infoNumber: {
    fontFamily: "CanterBold",
    fontSize: vw(15),
    color: "#00ffff"
  },
  infoText: {
    fontFamily: "CanterBold",
    fontSize: 42,
    color: "#00ffff",
    alignSelf: 'flex-end'
  },
  infinity: {
    fontFamily: "CanterBold",
    fontSize: 43,
    color: "#00ffff"
  },
})
