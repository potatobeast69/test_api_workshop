//
//  Matrix5x5.swift
//  POLARIS ARENA
//
//  Grid coordinate system and neighbor calculations
//

import Foundation

/// Represents a position on the 5x5 grid
struct Coord: Hashable, Codable {
    let row: Int  // 0...4
    let col: Int  // 0...4

    init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }

    /// Create from chess-style notation (A1-E5)
    init?(notation: String) {
        guard notation.count == 2 else { return nil }
        let chars = Array(notation.uppercased())

        // Column: A=0, B=1, C=2, D=3, E=4
        guard let colChar = chars.first,
              let col = "ABCDE".firstIndex(of: colChar) else { return nil }

        // Row: 1=0, 2=1, 3=2, 4=3, 5=4
        guard let rowDigit = chars.last?.wholeNumberValue,
              rowDigit >= 1 && rowDigit <= 5 else { return nil }

        self.row = rowDigit - 1
        self.col = Int("ABCDE".distance(from: "ABCDE".startIndex, to: col))
    }

    /// Convert to chess-style notation
    var notation: String {
        let colLetter = ["A", "B", "C", "D", "E"][col]
        let rowNumber = row + 1
        return "\(colLetter)\(rowNumber)"
    }

    /// Check if coordinate is within 5x5 bounds
    var isValid: Bool {
        return row >= 0 && row < 5 && col >= 0 && col < 5
    }

    /// Check if coordinate is at the center (C3)
    var isCenter: Bool {
        return row == 2 && col == 2
    }

    /// Check if coordinate is at the edge
    var isEdge: Bool {
        return row == 0 || row == 4 || col == 0 || col == 4
    }

    /// Manhattan distance to another coordinate
    func distance(to other: Coord) -> Int {
        return abs(row - other.row) + abs(col - other.col)
    }
}

/// Direction vectors for neighbors
enum Direction: CaseIterable {
    case north, south, east, west
    case northEast, northWest, southEast, southWest

    var offset: (row: Int, col: Int) {
        switch self {
        case .north: return (-1, 0)
        case .south: return (1, 0)
        case .east: return (0, 1)
        case .west: return (0, -1)
        case .northEast: return (-1, 1)
        case .northWest: return (-1, -1)
        case .southEast: return (1, 1)
        case .southWest: return (1, -1)
        }
    }

    var isAxial: Bool {
        switch self {
        case .north, .south, .east, .west:
            return true
        default:
            return false
        }
    }

    var isDiagonal: Bool {
        return !isAxial
    }

    /// Opposite direction
    var opposite: Direction {
        switch self {
        case .north: return .south
        case .south: return .north
        case .east: return .west
        case .west: return .east
        case .northEast: return .southWest
        case .northWest: return .southEast
        case .southEast: return .northWest
        case .southWest: return .northEast
        }
    }
}

extension Coord {
    /// Get neighbor in a specific direction
    func neighbor(in direction: Direction) -> Coord? {
        let offset = direction.offset
        let newCoord = Coord(row: row + offset.row, col: col + offset.col)
        return newCoord.isValid ? newCoord : nil
    }

    /// Get all valid neighbors (8-directional)
    func neighbors(axialOnly: Bool = false) -> [Direction: Coord] {
        let directions = axialOnly
            ? Direction.allCases.filter { $0.isAxial }
            : Direction.allCases

        var result: [Direction: Coord] = [:]
        for dir in directions {
            if let neighbor = neighbor(in: dir) {
                result[dir] = neighbor
            }
        }
        return result
    }

    /// Get coordinate in direction, even if out of bounds
    func step(in direction: Direction) -> Coord {
        let offset = direction.offset
        return Coord(row: row + offset.row, col: col + offset.col)
    }

    /// Get direction from this coordinate to another
    func direction(to other: Coord) -> Direction? {
        let dr = other.row - row
        let dc = other.col - col

        // Must be adjacent
        guard abs(dr) <= 1 && abs(dc) <= 1 && (dr != 0 || dc != 0) else {
            return nil
        }

        switch (dr, dc) {
        case (-1, 0): return .north
        case (1, 0): return .south
        case (0, 1): return .east
        case (0, -1): return .west
        case (-1, 1): return .northEast
        case (-1, -1): return .northWest
        case (1, 1): return .southEast
        case (1, -1): return .southWest
        default: return nil
        }
    }
}

/// The 5x5 game grid
struct Matrix5x5<T> {
    private var cells: [[T?]]

    init() {
        self.cells = Array(repeating: Array(repeating: nil, count: 5), count: 5)
    }

    init(defaultValue: T) {
        self.cells = Array(repeating: Array(repeating: defaultValue, count: 5), count: 5)
    }

    subscript(coord: Coord) -> T? {
        get {
            guard coord.isValid else { return nil }
            return cells[coord.row][coord.col]
        }
        set {
            guard coord.isValid else { return }
            cells[coord.row][coord.col] = newValue
        }
    }

    subscript(row: Int, col: Int) -> T? {
        get {
            return self[Coord(row: row, col: col)]
        }
        set {
            self[Coord(row: row, col: col)] = newValue
        }
    }

    /// Get all coordinates that contain values
    func occupiedCoords() -> [Coord] {
        var result: [Coord] = []
        for row in 0..<5 {
            for col in 0..<5 {
                let coord = Coord(row: row, col: col)
                if self[coord] != nil {
                    result.append(coord)
                }
            }
        }
        return result
    }

    /// Count occupied cells
    func occupiedCount() -> Int {
        return occupiedCoords().count
    }

    /// Get all coordinates
    static func allCoords() -> [Coord] {
        var result: [Coord] = []
        for row in 0..<5 {
            for col in 0..<5 {
                result.append(Coord(row: row, col: col))
            }
        }
        return result
    }
}
