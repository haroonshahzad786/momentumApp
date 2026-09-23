export default interface props {
  data: Array<{
    date: string
    answers: Array<{
      answer: string
      question_number: number
    }>
  }>
  questions: Array<string>
  isLoading?: boolean
}
