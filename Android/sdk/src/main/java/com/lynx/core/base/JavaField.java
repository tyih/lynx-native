// Copyright 2017 The Lynx Authors. All rights reserved.
package com.lynx.core.base;

import com.lynx.core.annotation.JSField;

/**
 * An identifiable wrapper for Java field
 */

/* package */ class JavaField {
    private JavaMethod mGetMethod;
    private JavaMethod mSetMethod;
    private String mFieldName;

    public JavaField(String field) {
        mFieldName = field;
    }

    public Object get(Object receiver) {
        if (mGetMethod != null) {
            return mGetMethod.invoke(receiver);
        }
        return null;
    }

    public void set(Object receiver, Object arg) {
        if (mSetMethod != null) {
            mSetMethod.invoke(receiver, arg);
        }
    }

    public void linkMethod(JavaMethod method, JSField annotation) {
        if (annotation.method() == JSField.Method.Get) {
            if (method.getParameterLength() > 0) {
                throw new RuntimeException(method.getDeclaringClass().getCanonicalName() +
                        " has Get Method which should not has arguments");
            }
            mGetMethod = method;
        } else {
            if (method.getParameterLength() > 1) {
                throw new RuntimeException(method.getDeclaringClass().getCanonicalName() +
                        " has Set Method which should not has more than one argument");
            }
            mSetMethod = method;
        }
    }

    public String getName() {
        return mFieldName;
    }

    public String getFieldType() {
        if (mSetMethod != null) {
            return mSetMethod.getParameterTypes().getTransformTypes();
        }
        if (mGetMethod != null) {
            return mGetMethod.getReturnType().getTransformTypes();
        }
        throw new RuntimeException("field type not find");
    }

    public Class getDeclaringClass() {
        if (mSetMethod != null) {
            return mSetMethod.getDeclaringClass();
        }
        if (mGetMethod != null) {
            return mGetMethod.getDeclaringClass();
        }
        return null;
    }

}
