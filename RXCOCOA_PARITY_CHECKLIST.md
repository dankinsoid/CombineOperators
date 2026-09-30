# RxCocoa → CombineCocoa Parity Checklist

Полный чеклист для достижения паритета с RxCocoa. Прогресс отслеживается по категориям.

---

## 📊 Общая статистика

### Реализовано
- ✅ **Core Infrastructure**: 10/11 (91%)
- ✅ **Basic Traits**: 2/2 (100%) - Driver/Signal не нужны для Combine
- ⚠️ **Foundation**: 2/8 (25%)
- ⚠️ **iOS UIKit Controls**: 16/26 (62%)
- ❌ **iOS Collections & DataSources**: 0/12 (0%)
- ❌ **iOS Proxies**: 0/18 (0%)
- ✅ **Gestures**: 10/10 (100%)
- ❌ **macOS AppKit**: 0/6 (0%)
- ❌ **CombineTest** (аналог RxTest): 0/14 (0%)
- ⚠️ **Tests**: 31/~80 (39%)

### Приоритетность
- 🔴 **Critical** - Основной функционал, без которого невозможна работа
- 🟡 **Important** - Важный функционал, используется часто
- 🟢 **Nice to have** - Дополнительный функционал

---

## 1. Core Infrastructure (Common/)

### ✅ Реализовано
- [x] `Reactive.swift` - Базовые реактивные расширения
- [x] `Reactive+Cancellable.swift` - Cancellable support
- [x] `ReactiveBinder.swift` - Binder для реактивных свойств
- [x] `ControlTarget.swift` - UIControl target handling
- [x] `CombineTarget.swift` - Combine target handling
- [x] `DelegateProxy.swift` - Базовая реализация proxy
- [x] `DelegateProxyType.swift` - Протоколы proxy
- [x] `Deinit.swift` - Deinit utilities
- [x] `Dispatch.swift` - Dispatch queue utilities
- [x] `TextInput.swift` - Text input protocol
- [x] `SectionedViewDataSourceType.swift` - Протоколы datasource

### ❌ Отсутствует
- [ ] 🟡 `Observable+Bind.swift` - Полноценный биндинг для Publisher

---

## 2. Traits

### ✅ Реализовано (100%)
- [x] `ControlEvent.swift` - Trait для UI событий
- [x] `ControlProperty.swift` - Trait для UI свойств

**Примечание:** Driver/Signal из RxCocoa не нужны для Combine. Эти концепции специфичны для RxSwift и плохо ложатся в архитектуру Combine. В Combine их роль выполняют:
- `.receive(on: MainScheduler.instance)`

---

## 3. Foundation Extensions

### ✅ Реализовано
- [x] `NSObject+Combine.swift` - Базовые расширения NSObject
- [x] `URLSession+Combine.swift` - Network requests

### ❌ Отсутствует

#### KVO (Key-Value Observing)
- [ ] 🔴 `NSObject+Rx+KVORepresentable.swift` - KVO наблюдение за свойствами (есть нативная реализация .publisher(for:))
- [ ] 🔴 `KVORepresentable.swift` - Протокол для наблюдаемых свойств
- [ ] 🟡 `KVORepresentable+Swift.swift` - Swift типы (Int, String, Bool)
- [ ] 🟡 `KVORepresentable+CoreGraphics.swift` - CG типы (CGRect, CGPoint)
- [ ] 🟡 `NSObject+Rx+RawRepresentable.swift` - RawRepresentable properties

#### Notifications
- [ ] 🟡 `NotificationCenter+Combine.swift` - Notification observation
  - **Примечание:** Частично есть в `CombineOperators/NSNotification++.swift`, но нужно перенести в CombineCocoa

---

## 4. iOS UIKit Components

### ✅ Реализовано (16/26)
- [x] `UIControl+Combine.swift` - Базовые события контролов
- [x] `UIButton+Combine.swift` - Button tap
- [x] `UISwitch+Combine.swift` - Switch value
- [x] `UISlider+Combine.swift` - Slider value
- [x] `UIStepper+Combine.swift` - Stepper value
- [x] `UISegmentedControl+Combine.swift` - Segment selection
- [x] `UIDatePicker+Combine.swift` - Date selection
- [x] `UITextField+Combine.swift` - Text input
- [x] `UITextView+Combine.swift` - Multi-line text
- [x] `UILabel+Combine.swift` - Label text
- [x] `UIActivityIndicatorView+Combine.swift` - Loading indicator
- [x] `UIRefreshControl+Combine.swift` - Pull-to-refresh
- [x] `UIStackView+Combine.swift` - Stack view
- [x] `UIView+Combine.swift` - View properties
- [x] `UIBarButtonItem+Combine.swift` - Bar button tap
- [x] `UIGestureRecognizer+Combine.swift` - Gesture events

### ❌ Отсутствует (10/26)

#### Критичные компоненты
- [ ] 🔴 `UIScrollView+Combine.swift` - Scroll events, contentOffset, zoom
  - Методы: contentOffset, didScroll, didZoom, willBeginDragging, didEndDragging
- [ ] 🔴 `UITableView+Combine.swift` - Table data & delegate events
  - Методы: items, modelSelected, itemSelected, itemDeleted, modelDeleted
- [ ] 🔴 `UICollectionView+Combine.swift` - Collection data & delegate
  - Методы: items, modelSelected, itemSelected

#### Важные компоненты
- [ ] 🟡 `UIPickerView+Combine.swift` - Picker selection
- [ ] 🟡 `UISearchBar+Combine.swift` - Search text, buttons
- [ ] 🟡 `UISearchController+Combine.swift` - Search controller state
- [ ] 🟡 `UITabBar+Combine.swift` - Tab selection
- [ ] 🟡 `UITabBarController+Combine.swift` - Tab controller selection
- [ ] 🟡 `UINavigationController+Combine.swift` - Navigation events

#### Nice to have
- [ ] 🟢 `WKWebView+Combine.swift` - Web view navigation
- [ ] 🟢 `NSTextStorage+Combine.swift` - Text storage changes
- [ ] 🟢 `UIImageView+Combine.swift` - Image binding (если нужно)
- [ ] 🟢 `UIProgressView+Combine.swift` - Progress value (если нужно)

### ❌ Отсутствует: UIApplication расширения
- [ ] 🟡 Расширить `UIApplication+Combine.swift`:
  - applicationState
  - applicationIconBadgeNumber
  - Background/Foreground events

---

## 5. iOS DataSources & Adapters

Полностью отсутствуют! Это критичный функционал для работы с коллекциями.

### DataSources (0/3)
- [ ] 🔴 `RxTableViewReactiveArrayDataSource.swift`
  - Простой array-based datasource для UITableView
- [ ] 🔴 `RxCollectionViewReactiveArrayDataSource.swift`
  - Простой array-based datasource для UICollectionView
- [ ] 🟡 `RxPickerViewAdapter.swift`
  - Адаптер для UIPickerView

---

## 6. iOS Delegate Proxies

Полностью отсутствуют! Delegate Proxy - это ключевая архитектурная часть RxCocoa.

### Table View Proxies (0/3)
- [ ] 🔴 `RxTableViewDataSourceProxy.swift`
- [ ] 🔴 `RxTableViewDelegateProxy.swift`
- [ ] 🟡 `RxTableViewDataSourcePrefetchingProxy.swift`

### Collection View Proxies (0/3)
- [ ] 🔴 `RxCollectionViewDataSourceProxy.swift`
- [ ] 🔴 `RxCollectionViewDelegateProxy.swift`
- [ ] 🟡 `RxCollectionViewDataSourcePrefetchingProxy.swift`

### Scroll View Proxies (0/1)
- [ ] 🔴 `RxScrollViewDelegateProxy.swift`

### Picker Proxies (0/2)
- [ ] 🟡 `RxPickerViewDataSourceProxy.swift`
- [ ] 🟡 `RxPickerViewDelegateProxy.swift`

### Search Proxies (0/2)
- [ ] 🟡 `RxSearchBarDelegateProxy.swift`
- [ ] 🟡 `RxSearchControllerDelegateProxy.swift`

### Text Proxies (0/2)
- [ ] 🟡 `RxTextViewDelegateProxy.swift`
- [ ] 🟢 `RxTextStorageDelegateProxy.swift`

### Navigation Proxies (0/3)
- [ ] 🟡 `RxTabBarDelegateProxy.swift`
- [ ] 🟡 `RxTabBarControllerDelegateProxy.swift`
- [ ] 🟡 `RxNavigationControllerDelegateProxy.swift`

### Web Proxies (0/1)
- [ ] 🟢 `RxWKNavigationDelegateProxy.swift`

---

## 7. iOS Protocols

Полностью отсутствуют!

### DataSource Protocols (0/3)
- [ ] 🔴 `RxTableViewDataSourceType.swift`
  - Протокол для кастомных table datasources
- [ ] 🔴 `RxCollectionViewDataSourceType.swift`
  - Протокол для кастомных collection datasources
- [ ] 🟡 `RxPickerViewDataSourceType.swift`
  - Протокол для кастомных picker datasources

---

## 8. iOS Events

### ❌ Отсутствует (0/1)
- [ ] 🟡 `ItemEvents.swift`
  - События для item selection/deselection в коллекциях

---

## 9. Gestures

### ✅ Полностью реализовано (10/10) 🎉
- [x] `GestureRecognizer+CombineGesture.swift`
- [x] `View+CombineGesture.swift`
- [x] `GenericCombineGestureRecognizerDelegate.swift`
- [x] `GestureFactory.swift`
- [x] `SharedTypes.swift`
- [x] `UITapGestureRecognizer+CombineGesture.swift`
- [x] `UILongPressGestureRecognizer+CombineGesture.swift`
- [x] `UIPanGestureRecognizer+CombineGesture.swift`
- [x] `UIPinchGestureRecognizer+CombineGesture.swift`
- [x] `UIRotationGestureRecognizer+CombineGesture.swift`
- [x] `UISwipeGestureRecognizer+CombineGesture.swift`
- [x] `UIScreenEdgePanGestureRecognizer+CombineGesture.swift`
- [x] `UIHoverGestureRecognizer+CombineGesture.swift`
- [x] `ForceTouchGestureRecognizer.swift`
- [x] `TouchDownGestureRecognizer.swift`
- [x] `TransformGestureRecognizers.swift`

---

## 10. macOS AppKit Support

Полностью отсутствует поддержка macOS!

### macOS Controls (0/6)
- [ ] 🟡 `NSControl+Combine.swift` - Базовый контрол macOS
- [ ] 🟡 `NSButton+Combine.swift` - Button click
- [ ] 🟡 `NSSlider+Combine.swift` - Slider value
- [ ] 🟡 `NSTextField+Combine.swift` - Text input
- [ ] 🟡 `NSTextView+Combine.swift` - Rich text editing
- [ ] 🟡 `NSView+Combine.swift` - View lifecycle

**Примечание:** macOS поддержка - это отдельный большой блок работы. Можно отложить на потом.

---

## 11. CombineTest (аналог RxTest)

Полностью отсутствует! RxTest - это критичный инструмент для тестирования асинхронного кода.

**Примечание:** Вы используете новый Swift Testing framework, поэтому реализация будет отличаться от RxTest (который использует XCTest). Ниже - список компонентов RxTest для референса.

### Core Components (0/14)

#### Virtual Time Scheduling
- [ ] 🔴 `TestScheduler.swift` - Virtual time scheduler для детерминированного тестирования
  - Управление виртуальным временем
  - Методы: `start()`, `scheduleAt()`, `createHotObservable()`, `createColdObservable()`
  - Дефолтные времена: created=100, subscribed=200, disposed=1000
- [ ] 🔴 `TestSchedulerVirtualTimeConverter.swift` - Конвертация виртуального времени
  - Преобразование виртуального времени в реальное

#### Recorded Events
- [ ] 🔴 `Recorded.swift` - Структура для записи событий с временными метками
  - `time`: виртуальное время
  - `value`: значение события
- [ ] 🔴 `Recorded+Event.swift` - Factory методы для создания событий
  - `.next(time, element)` - создание next события
  - `.completed(time)` - создание completed события
  - `.error(time, error)` - создание error события
  - `.events()` - создание массива событий

#### Test Observables
- [ ] 🔴 `TestableObservable.swift` - Базовый класс для тестовых observables
  - Записывает subscriptions и события
  - Абстрактный класс для Hot/Cold
- [ ] 🔴 `HotObservable.swift` - Hot observable для тестов
  - События воспроизводятся в абсолютное время, независимо от подписок
  - События отправляются всем текущим подписчикам
- [ ] 🔴 `ColdObservable.swift` - Cold observable для тестов
  - События воспроизводятся относительно времени подписки
  - Каждому подписчику - своя копия событий

#### Test Observers
- [ ] 🔴 `TestableObserver.swift` - Observer, который записывает все события
  - Записывает события с временными метками
  - Для assertions в тестах

#### Subscription Tracking
- [ ] 🔴 `Subscription.swift` - Запись времени subscribe/unsubscribe
  - `subscribe`: время подписки
  - `unsubscribe`: время отписки (или Int.max)

#### Equatable Support
- [ ] 🟡 `Event+Equatable.swift` - Equatable для Event типов
  - Сравнение next, error, completed событий
  - Специальная логика для error (domain + code + description)
- [ ] 🟡 `Any+Equatable.swift` - Type-erased equatable wrapper
  - `AnyEquatable` для сравнения в тестах

#### Testing Framework Integration
- [ ] 🟢 `Testing+Combine.swift` - Интеграция с Swift Testing
  - **НОВЫЙ ФАЙЛ** - аналог `XCTest+Rx.swift` но для Swift Testing
  - Assertions для сравнения событий
  - Assertions для Publisher'ов
  - Custom macros для удобного тестирования

#### Utilities
- [ ] 🟢 `Platform/DataStructures/Bag.swift` - Bag data structure (если нужна)
  - Может быть не нужна, если есть альтернативы

### Дополнительно

**Отличия от RxTest:**
- RxTest использует XCTest → CombineTest будет использовать Swift Testing
- RxTest работает с Observable → CombineTest будет работать с Publisher
- RxTest использует Disposable → CombineTest будет использовать AnyCancellable

**Ключевая концепция:**
TestScheduler позволяет писать детерминированные тесты для асинхронного кода:
```swift
let scheduler = TestScheduler(initialClock: 0)

// Создаем холодный observable с событиями в относительное время
let xs = scheduler.createColdObservable([
    .next(10, "A"),
    .next(20, "B"),
    .completed(30)
])

// Создаем observer для записи результатов
let observer = scheduler.createObserver(String.self)

// Подписываемся в виртуальное время 100
scheduler.scheduleAt(100) {
    xs.subscribe(observer)
}

// Запускаем scheduler до времени 200
scheduler.start()

// События будут записаны в observer в виртуальное время:
// 110: .next("A")  (100 + 10)
// 120: .next("B")  (100 + 20)
// 130: .completed  (100 + 30)
```

---

## 12. Tests

### ✅ Реализованные тесты (31 файл)

#### CombineOperators Tests (21/21) ✅
- [x] Publisher+OptionalTests
- [x] Publisher+EventsTests
- [x] Publisher+ErrorHandlingTests
- [x] Publisher+TransformationsTests
- [x] Publisher+TypedExtensionsTests
- [x] Publisher+WeakReferenceTests
- [x] AnyPublisher+FactoryTests
- [x] BinderTests
- [x] Cancellable++Tests
- [x] Subscriber++Tests
- [x] MainSchedulerTests
- [x] AsyncTests
- [x] OnDeinitTests
- [x] LockTests
- [x] NSNotification++Tests
- [x] CombineErrorTests
- [x] ReplaySubjectTests
- [x] SmoothTests
- [x] OperatorsTests
- [x] MergeBuilderTests

#### CombineCocoa Tests (10/~40)
- [x] ReactiveTests
- [x] ControlEventTests
- [x] ControlPropertyTests
- [x] ReactiveBinderTests
- [x] UIControl+CombineTests
- [x] UIButton+CombineTests
- [x] UISwitch+CombineTests
- [x] UISlider+CombineTests
- [x] UITextField+CombineTests
- [x] UITextView+CombineTests

### ❌ Отсутствующие тесты для CombineCocoa

#### Foundation Tests
- [ ] 🔴 `NSObject+CombineTests.swift` - Расширенные тесты для NSObject (KVO)
- [ ] 🟡 `URLSession+CombineTests.swift` - Тесты для URLSession
- [ ] 🟡 `NotificationCenter+CombineTests.swift` - Тесты для Notifications

#### iOS UIKit Tests (отсутствует ~15 файлов)
- [ ] 🟡 `UIDatePicker+CombineTests.swift`
- [ ] 🟡 `UIStepper+CombineTests.swift`
- [ ] 🟡 `UISegmentedControl+CombineTests.swift`
- [ ] 🟡 `UILabel+CombineTests.swift`
- [ ] 🟡 `UIActivityIndicatorView+CombineTests.swift`
- [ ] 🟡 `UIRefreshControl+CombineTests.swift`
- [ ] 🟡 `UIStackView+CombineTests.swift`
- [ ] 🟡 `UIView+CombineTests.swift`
- [ ] 🟡 `UIBarButtonItem+CombineTests.swift`
- [ ] 🟡 `UIGestureRecognizer+CombineTests.swift`
- [ ] 🟡 `UIApplication+CombineTests.swift`
- [ ] 🔴 `UIScrollView+CombineTests.swift` (когда будет реализован компонент)
- [ ] 🔴 `UITableView+CombineTests.swift` (когда будет реализован)
- [ ] 🔴 `UICollectionView+CombineTests.swift` (когда будет реализован)
- [ ] 🟡 `UIPickerView+CombineTests.swift` (когда будет реализован)
- [ ] 🟡 `UISearchBar+CombineTests.swift` (когда будет реализован)

#### Gesture Tests (0/10+)
- [ ] 🟡 `UITapGestureRecognizer+CombineGestureTests.swift`
- [ ] 🟡 `UILongPressGestureRecognizer+CombineGestureTests.swift`
- [ ] 🟡 `UIPanGestureRecognizer+CombineGestureTests.swift`
- [ ] 🟡 `UIPinchGestureRecognizer+CombineGestureTests.swift`
- [ ] 🟡 `UIRotationGestureRecognizer+CombineGestureTests.swift`
- [ ] 🟡 `UISwipeGestureRecognizer+CombineGestureTests.swift`
- [ ] 🟡 `UIScreenEdgePanGestureRecognizer+CombineGestureTests.swift`
- [ ] 🟡 `UIHoverGestureRecognizer+CombineGestureTests.swift`
- [ ] 🟡 `ForceTouchGestureRecognizerTests.swift`
- [ ] 🟡 `TouchDownGestureRecognizerTests.swift`

#### Proxy & DataSource Tests
- [ ] 🔴 `DelegateProxyTests.swift`
- [ ] 🔴 `RxTableViewReactiveArrayDataSourceTests.swift` (когда будет реализован)
- [ ] 🔴 `RxCollectionViewReactiveArrayDataSourceTests.swift` (когда будет реализован)

#### macOS Tests (0/6+)
- [ ] 🟢 Все тесты для macOS компонентов (когда будут реализованы)

---

## 12. Runtime & Objective-C Integration

### ✅ Реализовано
- [x] `CombineCocoaRuntime` target с C/ObjC headers:
  - `CBCocoaRuntime.h`
  - `_CB.h`
  - `_CBDelegateProxy.h`
  - `_CBKVOObserver.h`
  - `_CBObjCRuntime.h`

### ❌ Возможно требуется
- [ ] 🟢 Проверить полноту реализации runtime utilities
- [ ] 🟢 Сравнить с RxCocoa runtime (`_RXObjCRuntime.m`, `_RXDelegateProxy.m`)

---

## 📋 Roadmap: Рекомендуемый порядок реализации

### Phase 1: Критичный функционал (4-6 недель)
1. **CombineTest** (аналог RxTest)
   - Критичный инструмент для тестирования асинхронного кода
   - Virtual time scheduler + TestableObserver/Observable
   - ~12-14 файлов + интеграция с Swift Testing

2. **UIScrollView + Proxy**
   - Базовый компонент для UITableView/UICollectionView
   - ~2 файла + тесты

3. **UITableView + DataSource + Proxies**
   - Самый используемый компонент
   - ~6 файлов + тесты

4. **UICollectionView + DataSource + Proxies**
   - Второй по важности компонент
   - ~6 файлов + тесты

### Phase 2: Важный функционал (3-4 недели)
5. **Foundation Extensions**
   - KVO support
   - NotificationCenter
   - ~6 файлов + тесты

6. **Search Components**
   - UISearchBar + Proxy
   - UISearchController + Proxy
   - ~4 файла + тесты

7. **Navigation Components**
   - UITabBar/UITabBarController
   - UINavigationController
   - ~6 файлов + тесты

8. **Picker Components**
   - UIPickerView + DataSource + Proxies
   - ~4 файла + тесты

### Phase 3: Полнота покрытия (2-3 недели)
9. **Дополнительные компоненты**
   - WKWebView
   - NSTextStorage
   - Другие missing компоненты
   - ~4 файла + тесты

10. **Тесты для существующих компонентов**
    - Gestures (10+ файлов)
    - UIKit controls (10+ файлов)
    - Foundation (3-4 файла)

### Phase 4: macOS Support (3-4 недели) - Optional
11. **macOS AppKit**
    - NSControl, NSButton, NSSlider, etc.
    - ~6 файлов + тесты

---

## 🎯 Метрики успеха

### Минимальный паритет (MVP)
- [x] ✅ Core Infrastructure: 100%
- [x] ✅ Traits: 100% (ControlEvent/ControlProperty достаточно)
- [ ] ⚠️ CombineTest: 100% (критично для тестирования!)
- [ ] ⚠️ UIKit Controls: 100%
- [ ] ⚠️ UITableView/UICollectionView: 100%
- [ ] ⚠️ Tests coverage: >70%

### Полный паритет
- [ ] CombineTest: 100%
- [ ] Foundation: 100%
- [ ] iOS Components: 100%
- [ ] Proxies: 100%
- [ ] DataSources: 100%
- [ ] Tests coverage: >85%
- [ ] macOS Support: 100%

---

## 📝 Примечания

### Отличия Combine от Rx
Некоторые концепции RxSwift не имеют прямого эквивалента в Combine:
- **Driver/Signal/SharedSequence**: Не нужны в Combine. Используйте стандартные паттерны:
  - `CurrentValueSubject` + `.receive(on: DispatchQueue.main)` вместо Driver
  - `PassthroughSubject` + `.receive(on: DispatchQueue.main)` вместо Signal
  - `.share()` для shared publishers
- **BehaviorRelay/PublishRelay**: В Combine есть `CurrentValueSubject` и `PassthroughSubject`
- **Disposable**: В Combine используется `AnyCancellable`
- **DisposeBag**: В Combine используется `Set<AnyCancellable>` или `@Published` property wrapper

### Архитектурные решения
- **DelegateProxy**: Уже реализован базовый вариант
- **Runtime Integration**: Уже есть CombineCocoaRuntime target
- **Gesture Recognition**: Полностью реализовано, отличается от RxCocoa (улучшенная версия)
- **CombineTest vs RxTest**:
  - Нужна адаптация под Swift Testing (вместо XCTest)
  - Основные концепции остаются: TestScheduler, Hot/Cold observables, Recorded events
  - Интеграция с `#expect` макросом вместо `XCTAssert*`

---

## 🔗 Ссылки на референс
- **RxCocoa source**: `RxSwift-main/RxCocoa/`
- **RxTest source**: `RxSwift-main/RxTest/`
- **Current implementation**: `Sources/CombineCocoa/`
- **Tests**: `Tests/CombineCocoaTests/`
- **Test Utilities**: `Tests/TestUtilities/` (базовые, но не полный аналог RxTest)

---

Последнее обновление: 2025-11-04
