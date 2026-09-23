export const typeFlame = (momentum: number | undefined = 0) => {
    if (momentum < 36) return require('../assets/images/cores/Thruster_Low.gif');
    if (momentum > 35 && momentum < 71) return require('../assets/images/cores/Thruster_Mid.gif');
    if (momentum > 70) return require('../assets/images/cores/Thruster_High.gif');
}