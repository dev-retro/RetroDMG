import Testing
@testable import RetroDMG

struct FFITests {
    @Test
    func createAndQueryMetadata() async throws {
        let h = retrodmg_create()
        defer { retrodmg_destroy(h) }
        #expect(h != 0)
        let year = retrodmg_release_year(h)
        #expect(year == 1989)
        if let namePtr = retrodmg_name(h) {
            let name = String(cString: namePtr)
            retrodmg_string_free(namePtr)
            #expect(name.contains("Game Boy"))
        } else {
            Issue.record("Name pointer is nil")
        }
    }

    @Test
    func inputsListAndSet() async throws {
        let h = retrodmg_create()
        defer { retrodmg_destroy(h) }
        let count = retrodmg_input_count(h)
        #expect(count == 8)
        // Check one name
        if let up = retrodmg_input_name(h, 0) {
            let s = String(cString: up)
            retrodmg_string_free(up)
            #expect(s == "Up")
        }
        // Toggle A on
        "A".withCString { cstr in
            retrodmg_set_input(h, cstr, 1, 1)
        }
    }

    @Test
    func viewportCopy() async throws {
        let h = retrodmg_create()
        defer { retrodmg_destroy(h) }
        // Expect 160*144 pixels
        let expectedCount = 160*144
        var buf = [Int32](repeating: 0, count: expectedCount)
        let written = retrodmg_viewport_copy(h, &buf, Int32(buf.count))
        #expect(Int(written) == expectedCount)
    }
}
