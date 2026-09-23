interface AtomEmpty {
  init: false
  isLoading: false
  request: null
  value: null
  error: null
}

interface AtomInit<T> {
  init: true
  isLoading: true
  request: T
  value: null
  error: null
}

interface AtomLoading<T> {
  init: true
  isLoading: true
  request: T
  value: null
  error: null
}

interface AtomValue<S> {
  init: true
  isLoading: false
  request: null
  value: S
  error: null
}

interface AtomError {
  init: true
  isLoading: false
  request: null
  value: null
  error: Error
}

interface AtomSubEmpty {
  subscribed: false
  data: null
}

interface AtomSubInit {
  subscribed: true
  data: null
}

interface AtomSubValue<T> {
  subscribed: true
  data: T
}

export type AtomLoadable<T, S> =
  | AtomEmpty
  | AtomInit<T>
  | AtomLoading<T>
  | AtomValue<S>
  | AtomError

export type AtomSubscription<T> = AtomSubEmpty | AtomSubInit | AtomSubValue<T>
