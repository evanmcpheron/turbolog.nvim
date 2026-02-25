/* eslint-disable no-console */

/**
 * rocketlog.nvim test fixture
 *
 * Intentionally includes:
 * - semicolon + no-semicolon styles
 * - multiline expressions
 * - nested objects/arrays
 * - template literals
 * - function calls / chained calls
 * - async/await
 * - existing console logs
 * - awkward formatting
 *
 * Goal: syntax variety for plugin testing, not business logic.
 */

;

/* ---------------------------------- */
/* 0) Shared types                    */
/* ---------------------------------- */

type InvitationStatus = "PENDING" | "ACCEPTED" | "DECLINED";

type Invitation = {
  id: string;
  status: InvitationStatus;
  email: string;
  sentAt: string;
};

type Theme = "light" | "dark" | "system";

type UserProfile = {
  displayName: string;
  preferences?: {
    theme?: Theme;
    compactMode?: boolean;
  };
};

type User = {
  id: string;
  isActive: boolean;
  profile: UserProfile | null;
};

type PropertyData = {
  displayName: string;
  address: {
    line1: string;
    line2: string;
    city: string;
    state: string;
    zip: string;
  };
  amenities: string[];
  metadata?: {
    units?: number;
    petFriendly?: boolean;
  };
};

type QueryOptions = {
  ok?: boolean;
  nested?: {
    yes?: boolean;
    flags?: string[];
  };
  timeoutMs?: number;
  traceId?: string;
};

type QueryRow = {
  id: string;
  displayName?: string;
  sql?: string;
  params?: readonly unknown[];
  options?: QueryOptions;
  name?: string;
  payload?: Record<string, unknown>;
  tags?: string[];
};

type QueryResult<T extends QueryRow> = {
  rows: T[];
  rowCount: number;
};

type ComputeOptions = {
  includeTax: boolean;
  taxRate: number;
};

type BuildPayload = {
  companyId: string;
  property: PropertyData;
  tags: string[];
};

type GenericBox<T> = {
  value: T;
  meta: {
    createdAt: string;
    source: "test";
  };
};

/* ---------------------------------- */
/* 1) Base fixture data               */
/* ---------------------------------- */

const invitations: Invitation[] = [
  {
    id: "inv-1",
    status: "PENDING",
    email: "pending.one@example.com",
    sentAt: "2026-02-20T10:00:00.000Z",
  },
  {
    id: "inv-2",
    status: "ACCEPTED",
    email: "accepted@example.com",
    sentAt: "2026-02-18T10:00:00.000Z",
  },
  {
    id: "inv-3",
    status: "PENDING",
    email: "pending.two@example.com",
    sentAt: "2026-02-22T10:00:00.000Z",
  },
];

const users: User[] = [
  {
    id: "u1",
    isActive: true,
    profile: {
      displayName: "Evan",
      preferences: { theme: "dark", compactMode: true },
    },
  },
  {
    id: "u2",
    isActive: false,
    profile: {
      displayName: "Ashley",
      preferences: { theme: "light" },
    },
  },
  {
    id: "u3",
    isActive: true,
    profile: null,
  },
];

const propertyData: PropertyData = {
  displayName: "Cabin in the Woods",
  address: {
    line1: "123 Pine Lane",
    line2: "",
    city: "Greeneville",
    state: "TN",
    zip: "37743",
  },
  amenities: ["Fireplace", "Trail Access", "Hot Tub"],
  metadata: {
    units: 1,
    petFriendly: true,
  },
};

const userProfile: { company: { displayName: string } } = {
  company: {
    displayName: "Rocket Co",
  },
};

const someNewVar = {
  test: true
}

const companyIdFromProfile = "company-123";

/* ---------------------------------- */
/* 2) Basic filters/maps              */
/* ---------------------------------- */

const pendingInvitations = invitations.filter((inv) => inv.status === "PENDING");

const pendingEmails = invitations
  .filter((inv) => inv.status === "PENDING")
  .map((inv) => inv.email);

const activeNames = users
  .filter((u) => u.isActive)
  .map((u) => u.profile?.displayName ?? "Unknown")
  .sort((a, b) => a.localeCompare(b));

const activeNamesNoSemi = users
  .filter((u) => u.isActive)
  .map((u) => u.profile?.displayName ?? "Unknown")
  .sort((a, b) => a.localeCompare(b))

/* ---------------------------------- */
/* 3) Function calls / multiline      */
/* ---------------------------------- */

const queryParams = [companyIdFromProfile, "ACCOUNT_ADMIN"] as const;

const companyUsersQuery = fakeQuery(
  `
    SELECT *
    FROM company_users
    WHERE company_id = $1
    AND role = $2
  `,
  queryParams,
  { traceId: "trace-001", timeoutMs: 2500 }
);

const companyUsersQueryNoSemi = fakeQuery(
  "SELECT * FROM company_users WHERE company_id = $1",
  [companyIdFromProfile],
  { ok: true }
)

/* ---------------------------------- */
/* 4) Chained expressions             */
/* ---------------------------------- */

const normalizedAmenities = propertyData.amenities
  .map((item) => item.trim())
  .filter(Boolean)
  .map((item) => item.toLowerCase());

const normalizedAmenitiesNoSemi = propertyData.amenities
  .map((item) => item.trim())
  .filter(Boolean)
  .map((item) => item.toLowerCase())

/* ---------------------------------- */
/* 5) Optional chaining / nullish     */
/* ---------------------------------- */

const firstUserTheme = users[0]?.profile?.preferences?.theme ?? "system";
const secondUserTheme = users[1]?.profile?.preferences?.theme ?? "system";
const thirdUserTheme = users[2]?.profile?.preferences?.theme ?? "system";

const deepAccessValue = userProfile.company.displayName;
const deepOptionalValue = users[0]?.profile?.preferences?.theme ?? "system";

/* ---------------------------------- */
/* 6) Inline object/array literals    */
/* ---------------------------------- */

const inlineObj = { a: 1, b: { c: 2, d: [3, 4] } };
const inlineArr = [1, { x: 2 }, [3, 4, { y: 5 }]];

const inlineObjNoSemi = { a: 1, b: { c: 2, d: [3, 4] } }
const inlineArrNoSemi = [1, { x: 2 }, [3, 4, { y: 5 }]]

/* ---------------------------------- */
/* 7) Template literals               */
/* ---------------------------------- */

const sqlText = `
  SELECT *
  FROM properties
  WHERE company_id = $1
  AND deleted_at IS NULL
`;

const sqlTextNoSemi = `
  SELECT *
  FROM company_users
  WHERE role = 'ACCOUNT_ADMIN'
`

const trickyTemplateCase = `
  fake tokens: () {} [] ;
  actual value: ${propertyData.address.city}
`;

/* ---------------------------------- */
/* 8) Weird formatting                */
/* ---------------------------------- */

const weirdFormatted = fakeQuery("SELECT 1", [1, 2, 3], { ok: true })

const anotherWeird =
  fakeQuery(
    "SELECT * FROM x WHERE y = $1",
    [
      "abc",
    ],
    {
      nested: {
        yes: true,
        flags: ["a", "b"],
      },
    }
  )

/* ---------------------------------- */
/* 9) Heuristic trouble cases         */
/* ---------------------------------- */

// Semicolon inside a string before statement ends:
const trickyStringCase = fakeQuery(
  "SELECT ';' as semicolon_char, '(' as open_paren",
  [1, 2, 3],
  { traceId: "semicolon-test" }
);

// Comment with symbols (heuristic may miscount if scanning comments naively)
// () {} [] ;
const commentSymbolsCase = {
  note: "Comment above contains bracket-like tokens",
  ok: true,
};

/* ---------------------------------- */
/* 10) Existing console logs          */
/* ---------------------------------- */

const alreadyLogged = "you can test inserting another log after this";
console.log("existing log:", alreadyLogged);

const rocketStyle = {
  file: "company.service.ts",
  line: 184,
  label: "queryParams",
};

console.error("existing error log:", rocketStyle);
console.warn("existing warn log:", pendingInvitations.length)
console.info("existing info log:", { activeNames });

/* ---------------------------------- */
/* 11) Return statements              */
/* ---------------------------------- */

function buildPayload(): BuildPayload {
  const payload: BuildPayload = {
    companyId: companyIdFromProfile,
    property: propertyData,
    tags: pendingInvitations.map((p) => p.id),
  };

  return payload;
}

const finalPayload = buildPayload();

/* ---------------------------------- */
/* 12) Arrow functions                */
/* ---------------------------------- */

const formatUserLabel = (user: User): string =>
  `${user.id}:${user.profile?.displayName ?? "Unknown"}`;

const userLabels = users.map((u) => formatUserLabel(u));

const sumLengths = (values: string[]): number =>
  values.reduce((acc, value) => acc + value.length, 0);

const labelsLengthTotal = sumLengths(userLabels);

/* ---------------------------------- */
/* 13) Generic helpers                */
/* ---------------------------------- */

function boxValue<T>(value: T): GenericBox<T> {
  return {
    value,
    meta: {
      createdAt: new Date().toISOString(),
      source: "test",
    },
  };
}

const boxedString = boxValue("rocket");
const boxedObject = boxValue({ id: "x", enabled: true });

/* ---------------------------------- */
/* 14) Async / await                  */
/* ---------------------------------- */

async function runAsyncScenario(): Promise<void> {
  const payload = buildPayload();
  const tags = ["alpha", "beta", "gamma"];

  const result = await fakeAsyncCall("load-company-users", payload, tags);

  const firstRow = result.rows[0];
  const maybeName = firstRow?.name ?? "unknown";

  console.log("async result rowCount:", result.rowCount);
  console.log("async first row name:", maybeName);
}

void runAsyncScenario();

/* ---------------------------------- */
/* 15) Conditional / ternary cases    */
/* ---------------------------------- */

const hasPending = pendingInvitations.length > 0;
const pendingSummary = hasPending ? "has pending invites" : "no pending invites";

const cityLabel =
  propertyData.address.city.length > 5
    ? `${propertyData.address.city} (long)`
    : `${propertyData.address.city} (short)`;

/* ---------------------------------- */
/* 16) Arrays + tuples + readonly     */
/* ---------------------------------- */

const coords: readonly [number, number] = [36.1638, -82.8310];
const [lat, lng] = coords;

const matrix: Array<Array<number>> = [
  [1, 2, 3],
  [4, 5, 6],
];

const flattened = matrix.flat();

/* ---------------------------------- */
/* 17) Switch / control flow          */
/* ---------------------------------- */

function invitationStatusLabel(status: InvitationStatus): string {
  switch (status) {
    case "PENDING":
      return "Pending";
    case "ACCEPTED":
      return "Accepted";
    case "DECLINED":
      return "Declined";
    default: {
      // Exhaustive check
      const neverStatus: never = status;
      return neverStatus;
    }
  }
}

const invitationLabels = invitations.map((inv) => invitationStatusLabel(inv.status));

/* ---------------------------------- */
/* 18) Classes (for method scenarios) */
/* ---------------------------------- */

class QueryBuilder {
  private readonly tableName: string;

  constructor(tableName: string) {
    this.tableName = tableName;
  }

  select(columns: string[]): string {
    return `SELECT ${columns.join(", ")} FROM ${this.tableName}`;
  }

  where(column: string, placeholder: string): string {
    return `${this.select(["*"])} WHERE ${column} = ${placeholder}`;
  }
}

const qb = new QueryBuilder("properties");
const qbSql = qb.where("company_id", "$1");
const qbQuery = fakeQuery(qbSql, [companyIdFromProfile], { traceId: "qb-1" });

/* ---------------------------------- */
/* 19) Implicit return object traps   */
/* ---------------------------------- */

const mappedUsers = users.map((u) => ({
  id: u.id,
  active: u.isActive,
  displayName: u.profile?.displayName ?? "Unknown",
}));

const mappedUsersNoSemi = users.map((u) => ({
  id: u.id,
  active: u.isActive,
  displayName: u.profile?.displayName ?? "Unknown",
}))

/* ---------------------------------- */
/* 20) IIFE / nested scopes           */
/* ---------------------------------- */

const iifeResult = (() => {
  const local = {
    count: invitations.length,
    city: propertyData.address.city,
  };

  return `${local.city}:${local.count}`;
})();

const iifeResultNoSemi = (() => {
  const local = {
    value: "nested",
    items: [1, 2, 3],
  }

  return `${local.value}:${local.items.length}`
})()

/* ---------------------------------- */
/* 21) Function expressions           */
/* ---------------------------------- */

const multiply = function (a: number, b: number): number {
  return a * b;
};

const multiplyNoSemi = function (a: number, b: number): number {
  return a * b
}

const multiplied = multiply(6, 7);

/* ---------------------------------- */
/* 22) Helpers (fake implementations) */
/* ---------------------------------- */

function fakeQuery(
  sql: string,
  params: readonly unknown[],
  options: QueryOptions
): QueryResult<QueryRow> {
  return {
    rows: [
      {
        id: "row-1",
        displayName: "Mock Property",
        sql,
        params,
        options,
      },
    ],
    rowCount: 1,
  };
}

async function fakeAsyncCall(
  name: string,
  payload: Record<string, unknown>,
  tags: string[]
): Promise<QueryResult<QueryRow>> {
  return Promise.resolve({
    rows: [
      {
        id: "async-row-1",
        name,
        payload,
        tags,
      },
    ],
    rowCount: 1,
  });
}

function computeTotal(
  numbers: number[],
  transform: (value: number) => number,
  options: ComputeOptions
): number {
  const subtotal = numbers.reduce((sum, n) => sum + transform(n), 0);
  if (!options.includeTax) return subtotal;

  const total = subtotal + subtotal * options.taxRate;
  return Number(total.toFixed(2));
}

/* ---------------------------------- */
/* 23) Extra scenarios for testing    */
/* ---------------------------------- */

const totals = computeTotal(
  [10, 20, 30],
  (n) => n,
  { includeTax: true, taxRate: 0.07 }
);

const totalsNoSemi = computeTotal(
  [10, 20, 30],
  (n) => n * 2,
  { includeTax: false, taxRate: 0.07 }
)

const nestedCallResult = fakeQuery(
  qb.where("role", "$1"),
  [invitationStatusLabel("PENDING")],
  { traceId: "nested-call", nested: { yes: true } }
);

const objectWithFunction = {
  id: "obj-1",
  run(input: string): string {
    return input.toUpperCase();
  },
};

const methodResult = objectWithFunction.run("hello");
