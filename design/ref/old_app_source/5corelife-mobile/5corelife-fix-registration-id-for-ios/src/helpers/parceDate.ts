import moment from 'moment';

export default (date: any) => {
    if (date) {
        let addZero = '';
        const formatMoment = moment(date, 'hh:mm a').format('LT')
        const lengthFormatMoment = formatMoment.split(':');
        if (lengthFormatMoment[0].length === 1) addZero = `0${formatMoment}`;
        else addZero = formatMoment;

        return addZero;
    }
}