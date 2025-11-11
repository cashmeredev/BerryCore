/* Simple C++ test program for g++ verification */
#include <iostream>
#include <string>
#include <vector>

using namespace std;

class TestClass {
private:
    string message;
public:
    TestClass(string msg) : message(msg) {}
    
    void display() {
        cout << "TestClass says: " << message << endl;
    }
};

int main() {
    cout << "Hello from g++ on BlackBerry!" << endl;
    cout << "C++ Standard: " << __cplusplus << endl;
    
    // Test string
    string greeting = "C++ is working!";
    cout << greeting << endl;
    
    // Test vector
    vector<int> numbers;
    for (int i = 1; i <= 5; i++) {
        numbers.push_back(i * 10);
    }
    
    cout << "Vector test: ";
    for (int num : numbers) {
        cout << num << " ";
    }
    cout << endl;
    
    // Test class
    TestClass test("Classes work!");
    test.display();
    
    cout << "\n✓ All C++ tests passed!" << endl;
    return 0;
}

