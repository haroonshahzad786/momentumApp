import { StyleSheet } from 'react-native'
import { vh,vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1
  },

  containerSub: {
    flex: 1
  },

  imageRocket:{
    width:'100%',
    height:'100%'
  },

  imageRocket2:{

  },

  layerRocket:{
    position:'absolute',
    // backgroundColor:'red',
  },
  colorLayer:{
    width:'100%'
  },
  rocket:{
    zIndex:7
  },
  rocket2:{
    zIndex:7,
    position: 'absolute',
    left: '17.4%',
    top: '3.5%',
     width: '65%',
     height: '65%',
  },
  wings:{
    zIndex:5
  },
  turbine:{
    zIndex:6,
  },
  turbine_out:{
    zIndex:8,
    marginLeft:'0.5%'
  },
  flame_principal:{
    zIndex:5,
    marginTop:'7%',
    marginLeft:'1%'
  },
  fullAnimation:{
    // width:'18%',
    width:'24%',
    marginTop:'36%'
  },
  fullAnimationPlus:{
    width:'25%',
    marginTop:'38%'
  },
  smallAnimation:{
    // width:'16%',
    width:'12%',
    marginTop:'42%'
  },
  emptySpace:{
    // backgroundColor:'red',
    alignItems:'center',
    justifyContent:'center',
  },
  duoLeft:{
    left:'6.5%',
    zIndex:4,
  },
  duoRight:{
    right:'6%',
    zIndex:4,
  },
  duoLeftComp:{
    left:'6.5%',
    zIndex:4,
    marginTop:'3%'
  },
  duoRightComp:{
    right:'6%',
    zIndex:4,
    marginTop:'3%'
  },
  duoLeftExtra:{
    left:'10.5%',
    zIndex:3,
  },
  duoRightExtra:{
    right:'10%',
    zIndex:3
  }
})
