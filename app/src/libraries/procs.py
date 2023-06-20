def billing_event(session,number_of_rows):
    import time
    dts = int(time.time() *1000)
    # session.sql(f"CALL SYSTEM$CREATE_BILLING_EVENT('NUM_ROWS', '', {dts}, {dts}, {number_of_rows * .1}, '', '')").collect()
    return "Ok"
