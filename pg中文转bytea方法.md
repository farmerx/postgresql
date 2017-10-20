## pg中文转bytea方法
------

### chinese_to_bytea

```
-- chinese_to_bytea 终端转bytea字节
CREATE OR REPLACE FUNCTION chinese_to_bytea (input text)
RETURNS text
AS
$$
    DECLARE
        retVal text[];
        inputVal text[] := Array(select regexp_matches(lower(input), '([\u4e00-\u9fa5]+)|([-a-zA-Z]+)', 'g'));
    BEGIN
        IF array_length(inputVal, 1) > 0 THEN
            FOR i IN 1 .. ARRAY_UPPER(inputVal, 1)
            LOOP
                IF inputVal[i][1] IS NULL THEN
                    IF inputVal[i][2] != '-' THEN
                        retVal = ARRAY_APPEND(retVal, inputVal[i][2]);
                    END IF;
                ELSE
                    retVal = ARRAY_APPEND(retVal,ltrim(text(textsend(inputVal[i][1])),'\x') );
                   
                END IF;
            END LOOP;
            RETURN array_to_string(retVal,'');
        ELSE
            RETURN array_to_string(inputVal,'');
        END IF;
    END;
$$
LANGUAGE plpgsql IMMUTABLE;

```
