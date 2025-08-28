import KeyPathable

@KeyPathable
struct Person {
    @KeyPath var name: String
    var age: Int
}

let person = Person(name: "John", age: 30)
